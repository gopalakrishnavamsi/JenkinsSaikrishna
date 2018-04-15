public with sharing class ChatterEvents {

	private static ChatterEvents self = null;
	private static final Integer FLAG_ENVELOPE_SENT = 1;
	private static final Integer FLAG_ENVELOPE_DELIVERED = 2;
	private static final Integer FLAG_ENVELOPE_COMPLETED = 4;
	private static final Integer FLAG_ENVELOPE_DECLINED = 8;
	private static final Integer FLAG_ENVELOPE_VOIDED = 16;
	private static final Integer FLAG_RECIPIENT_SENT = 32;
	private static final Integer FLAG_RECIPIENT_DELIVERED = 64;
	private static final Integer FLAG_RECIPIENT_COMPLETED = 128;
	private static final Integer FLAG_RECIPIENT_SIGNED = 256;
	private static final Integer FLAG_RECIPIENT_DECLINED = 512;

	public Boolean postEnvelopeSent { get; private set; }
	public Boolean postEnvelopeDelivered { get; private set; }
	public Boolean postEnvelopeCompleted { get; private set; }
	public Boolean postEnvelopeDeclined { get; private set; }
	public Boolean postEnvelopeVoided { get; private set; }
	public Boolean postRecipientSent { get; private set; }
	public Boolean postRecipientDelivered { get; private set; }
	public Boolean postRecipientCompleted { get; private set; }
	public Boolean postRecipientSigned { get; private set; }
	public Boolean postRecipientDeclined { get; private set; }

	@TestVisible
	private ChatterEvents(
		final Boolean postEnvelopeSent,
		final Boolean postEnvelopeDelivered,
		final Boolean postEnvelopeCompleted,
		final Boolean postEnvelopeDeclined,
		final Boolean postEnvelopeVoided,
		final Boolean postRecipientSent,
		final Boolean postRecipientDelivered,
		final Boolean postRecipientCompleted,
		final Boolean postRecipientSigned,
		final Boolean postRecipientDeclined) {

		this.postEnvelopeSent = postEnvelopeSent;
		this.postEnvelopeDelivered = postEnvelopeDelivered;
		this.postEnvelopeCompleted = postEnvelopeCompleted;
		this.postEnvelopeDeclined = postEnvelopeDeclined;
		this.postEnvelopeVoided = postEnvelopeVoided;
		this.postRecipientSent = postRecipientSent;
		this.postRecipientDelivered = postRecipientDelivered;
		this.postRecipientCompleted = postRecipientCompleted;
		this.postRecipientSigned = postRecipientSigned;
		this.postRecipientDeclined = postRecipientDeclined;
	}

	public static ChatterEvents getInstance() {
		if (self == null) {
			self = unpack(Integer.valueOf(ChatterSettings__c.getOrgDefaults().Flags__c));
		}
		return self;
	}

	public static ChatterEvents save(final ChatterEvents events) {
		if (events == null) throw new DocuSignException(Label.UndefinedArgument);

		ChatterSettings__c settings = ChatterSettings__c.getOrgDefaults();
		settings.Flags__c = pack(events);
		upsert settings;

		self = unpack(Integer.valueOf(settings.Flags__c));
		return self;
	}

	@TestVisible
	private static ChatterEvents unpack(final Integer flags) {
		return new ChatterEvents(
			flags != null && (flags & FLAG_ENVELOPE_SENT) == FLAG_ENVELOPE_SENT,
			flags != null && (flags & FLAG_ENVELOPE_DELIVERED) == FLAG_ENVELOPE_DELIVERED,
			flags != null && (flags & FLAG_ENVELOPE_COMPLETED) == FLAG_ENVELOPE_COMPLETED,
			flags != null && (flags & FLAG_ENVELOPE_DECLINED) == FLAG_ENVELOPE_DECLINED,
			flags != null && (flags & FLAG_ENVELOPE_VOIDED) == FLAG_ENVELOPE_VOIDED,
			flags != null && (flags & FLAG_RECIPIENT_SENT) == FLAG_RECIPIENT_SENT,
			flags != null && (flags & FLAG_RECIPIENT_DELIVERED) == FLAG_RECIPIENT_DELIVERED,
			flags != null && (flags & FLAG_RECIPIENT_COMPLETED) == FLAG_RECIPIENT_COMPLETED,
			flags != null && (flags & FLAG_RECIPIENT_SIGNED) == FLAG_RECIPIENT_SIGNED,
			flags != null && (flags & FLAG_RECIPIENT_DECLINED) == FLAG_RECIPIENT_DECLINED);
	}

	@TestVisible
	private static Integer pack(final ChatterEvents events) {
		Integer flags = 0;
		if (events != null) {
			if (events.postEnvelopeSent) flags |= FLAG_ENVELOPE_SENT;
			if (events.postEnvelopeDelivered) flags |= FLAG_ENVELOPE_DELIVERED;
			if (events.postEnvelopeCompleted) flags |= FLAG_ENVELOPE_COMPLETED;
			if (events.postEnvelopeDeclined) flags |= FLAG_ENVELOPE_DECLINED;
			if (events.postEnvelopeVoided) flags |= FLAG_ENVELOPE_VOIDED;
			if (events.postRecipientSent) flags |= FLAG_RECIPIENT_SENT;
			if (events.postRecipientDelivered) flags |= FLAG_RECIPIENT_DELIVERED;
			if (events.postRecipientCompleted) flags |= FLAG_RECIPIENT_COMPLETED;
			if (events.postRecipientSigned) flags |= FLAG_RECIPIENT_SIGNED;
			if (events.postRecipientDeclined) flags |= FLAG_RECIPIENT_DECLINED;
		}
		return flags;
	}
}
