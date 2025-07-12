import { handleTaskCommand } from '@/utils/cli-handler';

describe('Example Test Suite', () => {
  it('should be true', () => {
    expect(true).toBe(true);
  });

  it('can call a function from src', () => {
    const consoleSpy = jest.spyOn(console, 'log').mockImplementation(() => {});

    handleTaskCommand('test-task-id', { simulate: true, verbose: false });

    expect(consoleSpy).toHaveBeenCalledWith('Executing task: test-task-id');
    expect(consoleSpy).toHaveBeenCalledWith('Simulation mode: ON');

    consoleSpy.mockRestore();
  });
});

describe('Basic Arithmetic', () => {
  it('should add two numbers correctly', () => {
    expect(1 + 1).toBe(2);
  });

  it('should multiply two numbers correctly', () => {
    expect(2 * 3).toBe(6);
  });
});

const fetchData = (): Promise<string> =>
  new Promise((resolve) => setTimeout(() => resolve('data'), 100));

describe('Async operations', () => {
  it('should resolve with data', async () => {
    const data = await fetchData();
    expect(data).toBe('data');
  });
});

describe('CLI Handler Extended Tests', () => {
  let consoleLogSpy: jest.SpiedFunction<typeof console.log>;
  let consoleWarnSpy: jest.SpiedFunction<typeof console.warn>;

  beforeEach(() => {
    consoleLogSpy = jest.spyOn(console, 'log').mockImplementation(() => {});
    consoleWarnSpy = jest.spyOn(console, 'warn').mockImplementation(() => {});
  });

  afterEach(() => {
    consoleLogSpy.mockRestore();
    consoleWarnSpy.mockRestore();
  });

  it('should warn on unknown task ID', () => {
    handleTaskCommand('unknown-task', {});
    expect(consoleWarnSpy).toHaveBeenCalledWith(
      expect.stringContaining('Warning: Task ID')
    );
  });

  it('should finish processing task if verbose', () => {
    handleTaskCommand('example-task', { verbose: true });
    expect(consoleLogSpy).toHaveBeenCalledWith(
      expect.stringContaining('Finished processing task:')
    );
  });
});
