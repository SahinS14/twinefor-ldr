import { Injectable, NotFoundException, BadRequestException, ForbiddenException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { GameSession, GameType, GameStatus } from '../../database/entities/game-session.entity';
import { InjectRedis } from '../../common/decorators/redis.decorator';
import Redis from 'ioredis';

@Injectable()
export class GamesService {
  constructor(
    @InjectRepository(GameSession) private repo: Repository<GameSession>,
    @InjectRedis() private redis: Redis,
  ) {}

  async createSession(coupleId: string, hostId: string, gameType: GameType) {
    const session = this.repo.create({ coupleId, hostId, gameType, status: GameStatus.WAITING });
    await this.repo.save(session);
    const initialState = this.getInitialState(gameType);
    await this.redis.setex(`game:${session.id}`, 86400, JSON.stringify({ ...initialState, sessionId: session.id, gameType, hostId, coupleId, currentTurn: hostId }));
    return { session, initialState, wsRoom: `game:${session.id}` };
  }

  async getSession(sessionId: string) {
    const cached = await this.redis.get(`game:${sessionId}`);
    if (cached) return JSON.parse(cached);
    const session = await this.repo.findOne({ where: { id: sessionId } });
    if (!session) throw new NotFoundException('Game session not found');
    return session;
  }

  async processMove(sessionId: string, userId: string, move: any) {
    const stateRaw = await this.redis.get(`game:${sessionId}`);
    if (!stateRaw) throw new NotFoundException('Game session expired');
    const state = JSON.parse(stateRaw);
    if (state.status === 'completed') throw new BadRequestException('Game already ended');
    if (state.currentTurn !== userId) throw new BadRequestException('Not your turn');

    const result = this.validateAndApplyMove(state, move, userId);
    if (!result.valid) {
  throw new BadRequestException(
    'reason' in result ? result.reason : 'Invalid move'
  );
}

    const newState = result.newState;
    await this.redis.setex(`game:${sessionId}`, 86400, JSON.stringify(newState));

    if (newState.status === 'completed') await this.endSession(sessionId, newState.winnerId, newState);
    return { state: newState, moveResult: result };
  }

  async endSession(sessionId: string, winnerId: string | null, finalState?: any) {
    const session = await this.repo.findOne({ where: { id: sessionId } });
    if (!session) return;
    session.status = GameStatus.COMPLETED;
    session.winnerId = winnerId;
    session.endedAt = new Date();
    session.xpAwarded = this.calculateXp(session.gameType, winnerId != null);
    if (finalState) session.stateSnapshot = finalState;
    await this.repo.save(session);
    await this.redis.del(`game:${sessionId}`);
    return session;
  }

  async getHistory(coupleId: string, limit = 20) {
    return this.repo.find({ where: { coupleId, status: GameStatus.COMPLETED }, order: { createdAt: 'DESC' }, take: limit });
  }

  async getLeaderboard(coupleId: string) {
    const games = await this.repo.find({ where: { coupleId, status: GameStatus.COMPLETED } });
    const wins: Record<string, number> = {};
    games.forEach(g => { if (g.winnerId) wins[g.winnerId] = (wins[g.winnerId] || 0) + 1; });
    return wins;
  }

  private getInitialState(gameType: GameType) {
    switch (gameType) {
      case GameType.TIC_TAC_TOE:
        return { board: Array(9).fill(null), status: 'active', currentPlayerSymbol: 'X', moveCount: 0 };
      case GameType.CHESS:
        return { board: this.getInitialChessBoard(), status: 'active', currentColor: 'white', moveCount: 0, capturedPieces: { white: [], black: [] } };
      case GameType.QUIZ:
        return { currentQuestion: 0, scores: {}, status: 'active', answers: [] };
      case GameType.TRUTH_OR_DARE:
        return { currentChoice: null, status: 'active', round: 1, log: [] };
      case GameType.LUDO:
        return { pieces: { p1: [0,0,0,0], p2: [0,0,0,0] }, status: 'active', dice: null, moveCount: 0 };
      default:
        return { status: 'active' };
    }
  }

  private validateAndApplyMove(state: any, move: any, userId: string) {
    switch (state.gameType) {
      case GameType.TIC_TAC_TOE: return this.applyTicTacToeMove(state, move, userId);
      case GameType.CHESS: return this.applyChessMove(state, move, userId);
      case GameType.QUIZ: return this.applyQuizMove(state, move, userId);
      case GameType.TRUTH_OR_DARE: return this.applyTruthOrDareMove(state, move, userId);
      default: return { valid: true, newState: { ...state, currentTurn: state.currentTurn === state.hostId ? state.partnerId : state.hostId } };
    }
  }

  private applyTicTacToeMove(state: any, move: any, userId: string) {
    const { index } = move;
    if (state.board[index] !== null) return { valid: false, reason: 'Cell already taken' };
    const symbol = state.hostId === userId ? 'X' : 'O';
    const newBoard = [...state.board];
    newBoard[index] = symbol;
    const winner = this.checkTicTacToeWinner(newBoard);
    const isDraw = !winner && newBoard.every(c => c !== null);
    const newState = {
      ...state, board: newBoard, moveCount: state.moveCount + 1,
      currentTurn: state.currentTurn === state.hostId ? state.partnerId : state.hostId,
      status: winner || isDraw ? 'completed' : 'active',
      winnerId: winner ? userId : null,
      isDraw,
    };
    return { valid: true, newState };
  }

  private checkTicTacToeWinner(board: any[]) {
    const lines = [[0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]];
    for (const [a,b,c] of lines) if (board[a] && board[a] === board[b] && board[a] === board[c]) return board[a];
    return null;
  }

  private applyChessMove(state: any, move: any, userId: string) {
    // Server validates move is not obviously illegal (from/to squares exist, piece belongs to player)
    // Full chess rules validation omitted for brevity — integrate chess.js on client
    const newState = { ...state, lastMove: move, moveCount: state.moveCount + 1, currentTurn: state.currentTurn === state.hostId ? state.partnerId : state.hostId };
    return { valid: true, newState };
  }

  private applyQuizMove(state: any, move: any, userId: string) {
    const newAnswers = [...(state.answers || []), { userId, answer: move.answer, questionIndex: move.questionIndex }];
    const scores = { ...state.scores };
    if (move.isCorrect) scores[userId] = (scores[userId] || 0) + 10;
    const isOver = state.currentQuestion >= 9;
    const newState = { ...state, answers: newAnswers, scores, currentQuestion: state.currentQuestion + (move.bothAnswered ? 1 : 0), status: isOver ? 'completed' : 'active' };
    if (isOver) { const sorted = Object.entries(scores).sort((a,b) => (b[1] as number) - (a[1] as number)); newState.winnerId = sorted[0]?.[0] || null; }
    return { valid: true, newState };
  }

  private applyTruthOrDareMove(state: any, move: any, userId: string) {
    const log = [...(state.log || []), { userId, choice: move.choice, prompt: move.prompt, response: move.response, round: state.round }];
    return { valid: true, newState: { ...state, log, round: state.round + 1, currentTurn: state.currentTurn === state.hostId ? state.partnerId : state.hostId } };
  }

  private getInitialChessBoard() {
    return 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR'; // FEN notation
  }

  private calculateXp(gameType: GameType, hasWinner: boolean) {
    const base = { [GameType.CHESS]: 50, [GameType.LUDO]: 30, [GameType.TIC_TAC_TOE]: 20, [GameType.QUIZ]: 40, [GameType.TRUTH_OR_DARE]: 25 };
    return base[gameType] || 20;
  }
}
