library 'docusign-common'

def installTasks = [
  'Install JS Dependencies': {
    nodejsInstall([
      commitStatusContext: 'Install JS Dependencies',
      nodejsInstallMethod: 'npm'
    ])
  }
]

def additionalPreBuildTasks = [
  'ESLint': [
    command: '''npm run lint'''
  ]
]

def defaultSalesforceArgs = [
  jwtKeyFileCredsId: 'salesforce-jwt-key-file',
  consumerKeyCredsId: 'salesforce-consumer-key',
  hubUsername: 'dfsdev@devhub.com',
  orgDefFilePath: 'etc/test.json',
  scratchOrgName: 'scratchorg',
  adminUsername: 'DocuSign_Administrator'
]

def defaultPostBuildTests = [
  'Unit Test': [
    outputDir: 'tests',
    outputPath: 'tests/*-junit.xml',
    reporter: 'xunit',
    reportFormat: 'junit'
  ]
]


salesforcePipeline(
  appName: 'salesforce-core',
  installTasks: installTasks,
  buildTasks: additionalPreBuildTasks,
  postBuildTests: defaultPostBuildTests,
  salesforceArgs: defaultSalesforceArgs,
  doSonarQube: true
)

