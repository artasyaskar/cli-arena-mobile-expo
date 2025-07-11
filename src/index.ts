#!/usr/bin/env node

/**
 * Main CLI entry point for the application.
 */

import { Command } from 'commander';
import { handleTaskCommand } from './utils/cli-handler';

// Basic CLI setup
const program = new Command();

program
  .version('0.0.1')
  .description('CLI tool for managing and executing mobile development tasks.');

// Example command structure:
// my-cli task <task-id> --option <value>
program
  .command('task <task-id>')
  .description('Execute a specific task by its ID.')
  .option('-s, --simulate', 'Simulate task execution without making actual changes.')
  .option('-v, --verbose', 'Enable verbose logging.')
  .action((taskId: string, options: { simulate?: boolean; verbose?: boolean }) => {
    handleTaskCommand(taskId, options);
  });

// Fallback for unknown commands
program.on('command:*', () => {
  console.error(
    'Invalid command: %s\nSee --help for a list of available commands.',
    program.args.join(' '),
  );
  process.exit(1);
});

async function main() {
  // Parse arguments
  await program.parseAsync(process.argv);

  // If no command is given, show help
  if (!process.argv.slice(2).length) {
    program.outputHelp();
  }
}

main().catch((error) => {
  console.error(`An unexpected error occurred: ${error.message}`);
  if (error.stack) {
    // console.error(error.stack); // Optionally log stack for debugging
  }
  process.exit(1);
});
