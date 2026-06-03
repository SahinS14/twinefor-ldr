import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { DailyQuestion, QuestionAnswer, QuestionCategory } from '../../database/entities/question.entity';
import { InjectRedis } from '../../common/decorators/redis.decorator';
import Redis from 'ioredis';
import OpenAI from 'openai';

@Injectable()
export class AiService {
  private openai: OpenAI;
  private readonly logger = new Logger(AiService.name);

  constructor(
    private config: ConfigService,
    @InjectRepository(DailyQuestion) private questionsRepo: Repository<DailyQuestion>,
    @InjectRepository(QuestionAnswer) private answersRepo: Repository<QuestionAnswer>,
    @InjectRedis() private redis: Redis,
  ) {
    const apiKey = this.config.get('OPENAI_API_KEY');
    if (apiKey) this.openai = new OpenAI({ apiKey });
  }

  async getDailyQuestion(coupleId: string) {
    const cacheKey = `daily_q:${coupleId}:${new Date().toDateString()}`;
    const cached = await this.redis.get(cacheKey);
    if (cached) return JSON.parse(cached);

    // Pick a random question from DB
    const count = await this.questionsRepo.count();
    const skip = Math.floor(Math.random() * count);
    const questions = await this.questionsRepo.find({ skip, take: 1, order: { createdAt: 'ASC' } });
    const question = questions[0];

    if (!question) return this.getFallbackQuestion();
    await this.redis.setex(cacheKey, 86400, JSON.stringify(question));
    return question;
  }

  async submitAnswer(coupleId: string, userId: string, questionId: string, answer: string) {
    const existing = await this.answersRepo.findOne({ where: { coupleId, userId, questionId } });
    if (existing) { existing.answer = answer; await this.answersRepo.save(existing); return existing; }

    const record = this.answersRepo.create({ coupleId, userId, questionId, answer });
    await this.answersRepo.save(record);

    // Check if partner also answered — trigger AI comparison
    const allAnswers = await this.answersRepo.find({ where: { coupleId, questionId } });
    if (allAnswers.length >= 2) {
      await this.generateAnswerInsight(coupleId, questionId, allAnswers);
    }
    return record;
  }

  async getCompatibilityReport(coupleId: string) {
    const cacheKey = `compat:${coupleId}`;
    const cached = await this.redis.get(cacheKey);
    if (cached) return JSON.parse(cached);

    const answers = await this.answersRepo.find({ where: { coupleId }, order: { createdAt: 'DESC' }, take: 50 });
    if (answers.length < 4) return this.getDefaultCompatibility();

    if (!this.openai) return this.getDefaultCompatibility();

    try {
      const prompt = `You are a relationship psychologist AI. Analyze these couple Q&A answers and return a JSON compatibility report.

Answers: ${JSON.stringify(answers.slice(0, 20))}

Return ONLY valid JSON:
{
  "compatScore": 0-100,
  "loveLanguage": "primary detected love language",
  "communicationScore": 0-100,
  "emotionalScore": 0-100,
  "weekHighlight": "one positive observation",
  "suggestions": ["suggestion 1", "suggestion 2"],
  "patterns": ["pattern 1", "pattern 2"]
}`;

      const res = await this.openai.chat.completions.create({
        model: 'gpt-4o-mini',
        messages: [{ role: 'user', content: prompt }],
        response_format: { type: 'json_object' },
        max_tokens: 500,
      });

      const report = JSON.parse(res.choices[0].message.content);
      await this.redis.setex(cacheKey, 3600, JSON.stringify(report));
      return report;
    } catch (e) {
      this.logger.error('OpenAI error:', e.message);
      return this.getDefaultCompatibility();
    }
  }

  async getWeeklySummary(coupleId: string) {
    const cacheKey = `weekly:${coupleId}:${this.getWeekKey()}`;
    const cached = await this.redis.get(cacheKey);
    if (cached) return JSON.parse(cached);

    const summary = await this.getCompatibilityReport(coupleId);
    await this.redis.setex(cacheKey, 604800, JSON.stringify(summary));
    return summary;
  }

  async generateAiQuestion(category: QuestionCategory = QuestionCategory.DEEP) {
    if (!this.openai) return this.getFallbackQuestion();
    try {
      const res = await this.openai.chat.completions.create({
        model: 'gpt-4o-mini',
        messages: [{ role: 'user', content: `Generate 1 ${category} relationship question for couples. Return ONLY the question text, nothing else.` }],
        max_tokens: 100,
      });
      const q = this.questionsRepo.create({ question: res.choices[0].message.content.trim(), category, isAiGenerated: true });
      await this.questionsRepo.save(q);
      return q;
    } catch {
      return this.getFallbackQuestion();
    }
  }

  private async generateAnswerInsight(coupleId: string, questionId: string, answers: QuestionAnswer[]) {
    if (!this.openai) return;
    try {
      const question = await this.questionsRepo.findOne({ where: { id: questionId } });
      const res = await this.openai.chat.completions.create({
        model: 'gpt-4o-mini',
        messages: [{ role: 'user', content: `Question: "${question?.question}"\nAnswer 1: "${answers[0].answer}"\nAnswer 2: "${answers[1].answer}"\nGive a warm 2-sentence insight about what these answers reveal about this couple's connection. Be specific and encouraging.` }],
        max_tokens: 150,
      });
      const insight = res.choices[0].message.content.trim();
      for (const a of answers) { a.aiInsight = insight; await this.answersRepo.save(a); }
    } catch (e) { this.logger.error('Insight generation failed:', e.message); }
  }

  private getWeekKey() {
    const d = new Date(); const jan1 = new Date(d.getFullYear(), 0, 1);
    return `${d.getFullYear()}-W${Math.ceil((((d.getTime() - jan1.getTime()) / 86400000) + jan1.getDay() + 1) / 7)}`;
  }

  private getFallbackQuestion() {
    const questions = [
      { question: "What's a small thing I do that makes you feel most loved?", category: QuestionCategory.ROMANTIC },
      { question: "Where do you see us in 5 years?", category: QuestionCategory.FUTURE },
      { question: "What's your happiest memory of us so far?", category: QuestionCategory.DEEP },
      { question: "If you could relive one day with me, which would it be?", category: QuestionCategory.ROMANTIC },
    ];
    return questions[Math.floor(Math.random() * questions.length)];
  }

  private getDefaultCompatibility() {
    return { compatScore: 75, loveLanguage: 'Quality Time', communicationScore: 78, emotionalScore: 80, weekHighlight: 'You two have been connecting well this week!', suggestions: ['Try a new game together', 'Share a memory today'], patterns: ['Consistent daily interaction'] };
  }
}
