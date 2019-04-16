({
  setTokenValue: function (component) {
    var fieldMapping = component.get('v.fieldMapping');

    if ($A.util.isEmpty(fieldMapping) || $A.util.isEmpty(fieldMapping.apiName)) {
      return;
    }

    var signerNumber = component.get('v.parentIndex') + 1;
    var token = '<# <Signature Placeholder="\\' + fieldMapping.apiName + signerNumber + '\\" Hidden="true" /> #>';

    component.set('v.token', token);
  }
});