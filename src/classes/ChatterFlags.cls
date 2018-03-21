public class ChatterFlags {

	public static final Integer FLAG_ENVELOPE_SENT = 1;
	public static final Integer FLAG_ENVELOPE_DELIVERED = 2;
	public static final Integer FLAG_ENVELOPE_COMPLETED = 4;
	public static final Integer FLAG_ENVELOPE_DECLINED = 8;
	public static final Integer FLAG_ENVELOPE_VOIDED = 16;
	public static final Integer FLAG_RECIPIENT_SENT = 32;
	public static final Integer FLAG_RECIPIENT_DELIVERED = 64;
	public static final Integer FLAG_RECIPIENT_COMPLETED = 128;
	public static final Integer FLAG_RECIPIENT_SIGNED = 256;
	public static final Integer FLAG_RECIPIENT_DECLINED = 512;

	public static Integer pack(
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

		Integer flags = 0;
		if (postEnvelopeSent) flags |= FLAG_ENVELOPE_SENT;
		if (postEnvelopeDelivered) flags |= FLAG_ENVELOPE_DELIVERED;
		if (postEnvelopeCompleted) flags |= FLAG_ENVELOPE_COMPLETED;
		if (postEnvelopeDeclined) flags |= FLAG_ENVELOPE_DECLINED;
		if (postEnvelopeVoided) flags |= FLAG_ENVELOPE_VOIDED;
		if (postRecipientSent) flags |= FLAG_RECIPIENT_SENT;
		if (postRecipientDelivered) flags |= FLAG_RECIPIENT_DELIVERED;
		if (postRecipientCompleted) flags |= FLAG_RECIPIENT_COMPLETED;
		if (postRecipientSigned) flags |= FLAG_RECIPIENT_SIGNED;
		if (postRecipientDeclined) flags |= FLAG_RECIPIENT_DECLINED;

		return flags;
	}
}
