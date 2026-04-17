const appSemver = String.fromEnvironment(
  'APP_SEMVER',
  defaultValue: 'dev',
);

const appBuildNumber = String.fromEnvironment(
  'APP_BUILD_NUMBER',
  defaultValue: '0',
);

const appVersionLabel = 'v $appSemver + $appBuildNumber';
