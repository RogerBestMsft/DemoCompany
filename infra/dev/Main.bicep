module dcModule 'DevCenter.bicep' = {
  name: 'devCenterDeploy'
  params: {
    resource_prefix: 'bravo'
    devboxProjectAdmin: 'c8307c6a-8539-4540-8e45-e8fa520fd93c'
    devboxProjectUser: 'c8307c6a-8539-4540-8e45-e8fa520fd93c'
  }
}
