/**
	 * A DocuSign envelope's reminder and expiration settings.
	 */
public class Notifications {
	/**
	 * Whether or not to remind recipients to sign.
	 */
	@AuraEnabled
	public Boolean remind { get; private set; }
	/**
	 * How many days to wait before sending a reminder.
	 */
	@AuraEnabled
	public Integer remindAfterDays { get; private set; }
	/**
	 * How many days between sending reminders.
	 */
	@AuraEnabled
	public Integer remindFrequencyDays { get; private set; }
	/**
	 * Whether or not the envelope automatically expires (is voided).
	 */
	@AuraEnabled
	public Boolean expires { get; private set; }
	/**
	 * How many days before the envelope expires.
	 */
	@AuraEnabled
	public Integer expireAfterDays { get; private set; }
	/**
	 * How many days prior to expiration to send a warning to recipients.
	 */
	@AuraEnabled
	public Integer expireWarnDays { get; private set; }
	/**
	 * Whether or not to update Chatter with envelope and recipient events.
	 */
	@AuraEnabled
	public Boolean updateChatter { get; private set; }

	/**
	 * Constructs an envelope notification settings.
	 *
	 * @param remind Whether or not to remind recipients to sign.
	 * @param remindAfterDays How many days to wait before sending a reminder.
	 * @param remindFrequencyDays How many days between sending reminders.
	 * @param expires Whether or not the envelope automatically expires (is voided).
	 * @param expireAfterDays How many days before the envelope expires.
	 * @param expireWarnDays How many days prior to expiration to send a warning to recipients.
	 * @param updateChatter Whether or not to update Chatter with envelope and recipient events.
	 */
	public Notifications(
		final Boolean remind,
		final Integer remindAfterDays,
		final Integer remindFrequencyDays,
		final Boolean expires,
		final Integer expireAfterDays,
		final Integer expireWarnDays,
		final Boolean updateChatter) {

		this.remind = remind;
		this.remindAfterDays = remindAfterDays;
		this.remindFrequencyDays = remindFrequencyDays;
		this.expires = expires;
		this.expireAfterDays = expireAfterDays;
		this.expireWarnDays = expireWarnDays;
		this.updateChatter = updateChatter;
	}

	/**
	 * Creates a deep copy of the envelope notifications.
	 *
	 * @return A copy of the envelope notifications.
	 */
	public Notifications copy() {
		return new Notifications(
			this.remind,
			this.remindAfterDays,
			this.remindFrequencyDays,
			this.expires,
			this.expireAfterDays,
			this.expireWarnDays,
			this.updateChatter);
	}
}
