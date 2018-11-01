public class MetadataDeployCallback implements Metadata.DeployCallback {

	public void handleResult(final Metadata.DeployResult result, final Metadata.DeployCallbackContext context) {
		// TODO: Do something besides blindly log the result.
		LoggerService.getInstance().info(String.valueOf(result));
	}
}