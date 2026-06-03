import 'reflect-metadata';
import { DataSource } from 'typeorm';
import { DailyQuestion, QuestionCategory } from './entities/question.entity';
import * as dotenv from 'dotenv';
dotenv.config();

const questions = [
  { question: "What's a small thing I do that makes you feel most loved?", category: QuestionCategory.ROMANTIC },
  { question: "What's your happiest memory of us so far?", category: QuestionCategory.DEEP },
  { question: "Where do you see us in 5 years?", category: QuestionCategory.FUTURE },
  { question: "What's a funny habit of mine you secretly love?", category: QuestionCategory.FUNNY },
  { question: "If you could relive one day with me, which would it be and why?", category: QuestionCategory.ROMANTIC },
  { question: "What's something you've always wanted to tell me but haven't yet?", category: QuestionCategory.DEEP },
  { question: "What's one adventure you want us to go on together?", category: QuestionCategory.FUTURE },
  { question: "What song reminds you of us?", category: QuestionCategory.ROMANTIC },
  { question: "What's the most embarrassing thing I've done that you found adorable?", category: QuestionCategory.FUNNY },
  { question: "What's a dream you have that you've never shared with anyone?", category: QuestionCategory.DEEP },
  { question: "What would our perfect lazy Sunday look like?", category: QuestionCategory.ROMANTIC },
  { question: "If we had to pick one city to live in forever, which would it be?", category: QuestionCategory.FUTURE },
  { question: "What's something about me that surprised you when we first started dating?", category: QuestionCategory.DEEP },
  { question: "What's the weirdest food combination you secretly enjoy?", category: QuestionCategory.FUNNY },
  { question: "What's one thing about our relationship you're most proud of?", category: QuestionCategory.DEEP },
  { question: "What's a skill you want us to learn together?", category: QuestionCategory.FUTURE },
  { question: "What moment made you realize you were falling for me?", category: QuestionCategory.ROMANTIC },
  { question: "What's the best gift — not material — you've ever received from me?", category: QuestionCategory.DEEP },
  { question: "If we could have dinner with any couple from history, who would you pick?", category: QuestionCategory.FUNNY },
  { question: "What's one thing you want us to do differently in our relationship?", category: QuestionCategory.DEEP },
];

async function seed() {
  const ds = new DataSource({
    type: 'postgres',
    url: process.env.DATABASE_URL,
    entities: [DailyQuestion],
    synchronize: true,
    ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
  });

  await ds.initialize();
  const repo = ds.getRepository(DailyQuestion);
  const existing = await repo.count();
  if (existing > 0) {
    console.log(`✅ Already have ${existing} questions. Skipping seed.`);
  } else {
    for (const q of questions) {
      await repo.save(repo.create(q));
    }
    console.log(`✅ Seeded ${questions.length} daily questions`);
  }
  await ds.destroy();
}

seed().catch(console.error);
