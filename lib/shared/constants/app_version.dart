const appBuildVersion = String.fromEnvironment(
  'APP_BUILD_VERSION',
  defaultValue: 'dev',
);

const appVersionLabel = 'v$appBuildVersion';
