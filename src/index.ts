#!/usr/bin/env node

import { Command } from 'commander';
import { handleTaskCommand, listTasks, type TaskOptions } from '@/utils/cli-handler';

const program = new Command();

program
  .version('0.0.1')
  .description('CLI tool for managing and executing mobile development tasks.');

program
  .command('task [task-id]')
  .description('Execute a specific task by its ID. Use --list to view all tasks.')
  .option('-s, --simulate', 'Simulate task execution without making actual changes.')
  .option('-v, --verbose', 'Enable verbose logging.')
  .option('--list', 'List all available task IDs and descriptions.')
  .action((taskId: string | undefined, options: TaskOptions & { list?: boolean }) => {
    if (options.list || !taskId) {
      listTasks();
    } else {
      handleTaskCommand(taskId, options);
    }
  });

program.on('command:*', () => {
  console.error(
    '❌ Invalid command: %s\nSee --help for a list of available commands.',
    program.args.join(' '),
  );
  process.exit(1);
});

async function main(): Promise<void> {
  await program.parseAsync(process.argv);

  // Show help if no command was entered
  if (process.argv.length <= 2) {
    program.outputHelp();
  }
}

main().catch((error: unknown) => {
  if (error instanceof Error) {
    console.error(`❌ An unexpected error occurred: ${error.message}`);
  } else {
    console.error('❌ An unknown error occurred.');
  }
  process.exit(1);
});
