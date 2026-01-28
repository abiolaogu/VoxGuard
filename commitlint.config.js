module.exports = {
    extends: ['@commitlint/config-conventional'],
    rules: {
        'type-enum': [
            2,
            'always',
            [
                'feat',     // New feature
                'fix',      // Bug fix
                'docs',     // Documentation
                'style',    // Formatting
                'refactor', // Code restructuring
                'perf',     // Performance
                'test',     // Tests
                'build',    // Build system
                'ci',       // CI configuration
                'chore',    // Maintenance
                'revert',   // Revert changes
            ],
        ],
        'scope-enum': [
            2,
            'always',
            [
                'domain',       // Shared domain
                'web',          // Web package
                'flutter',      // Flutter package
                'android',      // Android package
                'ios',          // iOS package
                'hasura',       // Hasura backend
                'infra',        // Infrastructure
                'codegen',      // Code generation
                'deps',         // Dependencies
            ],
        ],
        'subject-case': [2, 'always', 'lower-case'],
        'header-max-length': [2, 'always', 100],
    },
};
