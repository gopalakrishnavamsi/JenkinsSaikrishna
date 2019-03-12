/**
 * Representation of a DocuSign Agreement.
 */
public class Agreement {

    /**
	 * The DocuSign Agreement name.
	 */
    @AuraEnabled
    public String name { get; private set; }
    /**
	 * Date and time when the Agreement was created.
	 */
    @AuraEnabled
    public Datetime createdDate { get; private set; }
    /**
	 * Agreement status
	 */
    @AuraEnabled
    public String status { get; private set; }

    public Agreement(
            final String name,
            final Datetime createdDate,
            final String status) {
        this.name = name;
        this.createdDate = createdDate;
        this.status = status;
    }

}