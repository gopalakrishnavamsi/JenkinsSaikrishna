library 'docusign-common'

def installTasks = [
  'Install JS Dependencies': {
    nodejsInstall([
      commitStatusContext: 'Install JS Dependencies',
      nodejsInstallMethod: 'npm'
    ])
  }
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
  ],
  'ESLint': [
    command: '''npm run lint'''
  ]
]


salesforcePipeline(
  appName: 'salesforce-core',
  installTasks: installTasks,
  postBuildTests: defaultPostBuildTests,
  salesforceArgs: defaultSalesforceArgs,
  doSonarQube: true
)

