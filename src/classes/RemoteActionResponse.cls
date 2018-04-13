public virtual class RemoteActionResponse {

	public List<Message> messages { get; private set; }
	public Boolean success { get; private set; }

	protected RemoteActionResponse(final Boolean success, final List<Message> messages) {
		this.success = success;
		this.messages = messages == null ? new List<Message>() : messages;
	}

	protected RemoteActionResponse(final Boolean success, final List<APIError> errors) {
		this.success = success;
		this.messages = new List<Message>();
		if (Collection.isNotEmpty(errors)) {
			for (APIError e : errors) {
				this.messages.add(new Message(MessageSeverity.Error, e.toString()));
			}
		}
	}

	public enum MessageSeverity {
		Success, Info, Warning, Error
	}

	public class Message {
		public MessageSeverity severity { get; private set; }
		public String description { get; private set; }

		public Message(final MessageSeverity severity, final String description) {
			this.severity = severity == null ? MessageSeverity.Warning : severity;
			this.description = description;
		}
	}
}
