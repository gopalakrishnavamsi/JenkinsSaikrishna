/**
 * The result of a validation.
 */
global class ValidationResult {
	/**
	 * Validation error messages.
	 */
	global List<String> messages { get; private set; }
	/**
	 * Read-only property indicating whether the validation was successful.
	 */
	public Boolean isValid {
		get {
			return Collection.isEmpty(messages);
		}
	}

	/**
	 * Constructs an empty validation result.
	 */
	public ValidationResult() {
		this(new List<String>());
	}

	/**
	 * Constructs a validation result with a single error message.
	 *
	 * @param message The error message.
	 */
	public ValidationResult(final String message) {
		this(String.isNotBlank(message) ? new List<String> { message } : new List<String>());
	}

	/**
	 * Constructs a validation result with multiple error messages.
	 *
	 * @param messages The error messages.
	 */
	public ValidationResult(final List<String> messages) {
		this.messages = messages == null ? new List<String>() : messages;
	}

	/**
	 * Generates a string representation of the validation result.
	 *
	 * @return The string representation of the validation result.
	 */
	override public String toString() {
		return Collection.mkString(this.messages, '\n');
	}

	/**
	 * Adds a single error message to the validation result.
	 *
	 * @param message The error message to add.
	 *
	 * @return The updated validation result.
	 */
	public ValidationResult add(final String message) {
		if (String.isNotBlank(message)) this.messages.add(message);
		return this;
	}

	/**
	 * Adds multiple error messages to the validation result.
	 *
	 * @param messages The error messages to add.
	 *
	 * @return The updated validation result.
	 */
	public ValidationResult add(final List<String> messages) {
		if (messages != null) this.messages.addAll(messages);
		return this;
	}

	/**
	 * Adds another validation result to the validation result.
	 *
	 * @param other The other validation result.
	 *
	 * @return The updated validation result.
	 */
	public ValidationResult add(final ValidationResult other) {
		if (other != null && Collection.isNotEmpty(other.messages)) {
			this.messages.addAll(other.messages);
		}
		return this;
	}

	/**
	 * Adds field-level security results to the validation result.
	 *
	 * @param flsResults The field-level security results.
	 *
	 * @return The updated validation result.
	 */
	public ValidationResult add(final Permissions.FlsResults flsResults) {
		if (flsResults != null && !flsResults.isAuthorized) {
			this.messages.add(flsResults.getErrorMessage());
		}
		return this;
	}
}
