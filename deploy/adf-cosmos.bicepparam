using './adf-cosmos.bicep'


param location = 'AustraliaEast'
param tags = {}
param uniqueNameFormat = '${toLower(trim('ais'))}-{0}-${uniqueString('ais')}'
param uniqueShortNameFormat = '${toLower(trim('ais'))}{0}${uniqueString('ais')}'
