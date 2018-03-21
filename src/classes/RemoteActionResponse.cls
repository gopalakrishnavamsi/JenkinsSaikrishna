public virtual class RemoteActionResponse {

	public List<String> messages { get; private set; }
	public Boolean success { get; private set; }

	protected RemoteActionResponse(final Boolean success, final List<APIError> errors) {
		this.success = success;
		this.messages = new List<String>();
		if (Collection.isNotEmpty(errors)) {
			for (APIError e : errors) {
				this.messages.add(e.toString());
			}
		}
	}
}
