import type { CodegenConfig } from '@graphql-codegen/cli';

const config: CodegenConfig = {
  schema: [
    {
      'http://localhost:8082/v1/graphql': {
        headers: {
          'x-hasura-admin-secret': 'acm_hasura_secret',
        },
      },
    },
  ],
  documents: ['src/**/*.{ts,tsx}'],
  generates: {
    './src/graphql/generated/types.ts': {
      plugins: [
        'typescript',
        'typescript-operations',
        'typescript-react-apollo',
      ],
      config: {
        withHooks: true,
        withHOC: false,
        withComponent: false,
        skipTypename: false,
        dedupeFragments: true,
      },
    },
  },
  ignoreNoDocuments: true,
};

export default config;
