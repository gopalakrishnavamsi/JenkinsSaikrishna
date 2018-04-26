/**
 * The results of post-install script execution.
 */
public class PostInstallResults {

	/**
	 * Post-install script step statuses:
	 * <ul>
	 *     <li><code>SKIPPED</code>: The step was skipped.</li>
	 *     <li><code>STARTED</code>: The step started but may not have completed.</li>
	 *     <li><code>SUCCESS</code>: The step completed successfully.</li>
	 *     <li><code>FAILURE</code>: The step failed.</li>
	 * </ul>
	 */
	public enum StepStatus {
		SKIPPED, STARTED, SUCCESS, FAILURE
	}

	/**
	 * A step in the post-install script.
	 */
	public class Step implements Comparable {
		/**
		 * Ordinal sequence of the post-install step.
		 */
		public Integer sequence { get; private set; }
		/**
		 * The name of the post-install step.
		 */
		public String name { get; private set; }
		/**
		 * The execution status of the post-install step.
		 */
		public StepStatus status { get; private set; }
		/**
		 * Additional context (e.g. error message) related to the post-install step.
		 */
		public Object context { get; private set; }

		private Step(final Integer sequence, final String name, final StepStatus status, final Object context) {
			this.sequence = sequence;
			this.name = name;
			this.status = status;
			this.context = context;
		}

		private Step complete(final Boolean success, final Object context) {
			this.status = success ? StepStatus.SUCCESS : StepStatus.FAILURE;
			this.context = context;
			return this;
		}

		private Step withSequence(final Integer sequence) {
			this.sequence = sequence;
			return this;
		}

		/**
		 * Used to sort post-install steps.
		 *
		 * @param compareTo The step to which to compare.
		 *
		 * @return The result of the comparison.
		 */
		public Integer compareTo(final Object compareTo) {
			Step other = (Step)compareTo;
			if (this.sequence == other.sequence) return 0;
			if (this.sequence > other.sequence) return 1;
			return -1;
		}

		private String getStatusString() {
			if (this.status == StepStatus.SUCCESS) {
				return Label.StepSuccess;
			} else if (this.status == StepStatus.FAILURE) {
				return Label.StepFailure;
			} else if (this.status == StepStatus.SKIPPED) {
				return Label.StepSkipped;
			}
			return Label.StepUnknown;
		}

		/**
		 * Generates a string representation of the post-install step.
		 *
		 * @return The string representation of the post-install step.
		 */
		override public String toString() {
			String result = null;
			if (this.status == StepStatus.FAILURE && this.context != null) {
				Exception ex = (Exception)this.context;
				result = String.format('[{0}]\t{1} - {2}', new List<String> {
					getStatusString(),
					this.name,
					ex.getMessage()
				});
			} else if (this.context != null) {
				result = String.format('[{0}]\t{1} - {2}', new List<String> {
					getStatusString(),
					this.name,
					String.valueOf(this.context)
				});
			} else {
				result = String.format('[{0}]\t{1}', new List<String> {
					getStatusString(),
					this.name
				});
			}
			return result;
		}
	}

	/**
	 * The number of steps in the post-install script.
	 */
	public Integer count { get; private set; }
	private Map<String, Step> stepMap;
	/**
	 * Whether the post install script was successful. All step statuses must either be <code>SUCCESS</code> or
	 * <code>SKIPPED</code> for the script to be considered successful.
	 */
	public Boolean success { get; private set; }

	/**
	 * Constructs empty post-install results.
	 */
	public PostInstallResults() {
		this.count = 0;
		this.stepMap = new Map<String, Step>();
		this.success = true;
	}

	/**
	 * Begins a post-install step.
	 *
	 * @param name The name of the post-install step.
	 *
	 * @return The current post-install results.
	 */
	public PostInstallResults beginStep(final String name) {
		stepMap.put(name, new Step(++this.count, name, StepStatus.STARTED, null));
		return this;
	}

	/**
	 * Skips a post-install step.
	 *
	 * @param name The name of the post-install step.
	 * @param reason Why the step was skipped.
	 *
	 * @return The current post-install results.
	 */
	public PostInstallResults skipStep(final String name, final String reason) {
		stepMap.put(name, new Step(++this.count, name, StepStatus.SKIPPED, reason));
		return this;
	}

	/**
	 * Ends a post-install step successfully.
	 *
	 * @param name The name of the post-install step.
	 *
	 * @return The current post-install results.
	 */
	public PostInstallResults endStepSuccess(final String name) {
		if (stepMap.containsKey(name)) {
			stepMap.put(name, stepMap.get(name).complete(true, null));
		} else {
			stepMap.put(name, new Step(++this.count, name, StepStatus.SUCCESS, null));
		}
		return this;
	}

	/**
	 * Ends a post-install step successfully with additional context.
	 *
	 * @param name The name of the post-install step.
	 * @param context Additional context.
	 *
	 * @return The current post-install results.
	 */
	public PostInstallResults endStepSuccess(final String name, final Object context) {
		if (stepMap.containsKey(name)) {
			stepMap.put(name, stepMap.get(name).complete(true, context));
		} else {
			stepMap.put(name, new Step(++this.count, name, StepStatus.SUCCESS, context));
		}
		return this;
	}

	/**
	 * Ends a post-install step unsuccessfully with error details.
	 *
	 * @param name The name of the post-install step.
	 * @param ex The exception that failed the step.
	 *
	 * @return The current post-install results.
	 */
	public PostInstallResults endStepFailure(final String name, final Exception ex) {
		if (stepMap.containsKey(name)) {
			stepMap.put(name, stepMap.get(name).complete(false, ex));
		} else {
			stepMap.put(name, new Step(++this.count, name, StepStatus.FAILURE, ex));
		}
		this.success = false;
		return this;
	}

	/**
	 * Adds post-install results to the current results.
	 *
	 * @param results The results to add.
	 *
	 * @return The current post-install results.
	 */
	public PostInstallResults addResults(final PostInstallResults results) {
		if (results != null) {
			for (Step s : results.getSteps()) {
				this.stepMap.put(s.name, s.withSequence(++this.count));
			}
			this.success &= results.success;
		}
		return this;
	}

	/**
	 * Adds named post-install results to the current results.
	 *
	 * @param name The name of the post-install results.
	 * @param results The results to add.
	 *
	 * @return The current post-install results.
	 */
	public PostInstallResults addResults(final String name, final PostInstallResults results) {
		if (results != null) {
			for (Step s : results.getSteps()) {
				this.stepMap.put(name + ' -> ' + s.name, s.withSequence(++this.count));
			}
			this.success &= results.success;
		}
		return this;
	}

	/**
	 * Gets all post-install step failure messages.
	 *
	 * @return The post-install failure messages.
	 */
	public List<String> getFailureMessages() {
		List<String> messages = new List<String>();
		for (Step s : getSteps()) {
			if (s.status == StepStatus.FAILURE) {
				String message = '';
				if (String.isNotBlank(s.name)) {
					message += s.name + '\n';
				}
				if (s.context instanceof Exception) {
					Exception ex = (Exception)s.context;
					message += String.format('{0}: {1}\n{2}', new List<String> {
						ex.getTypeName(),
						ex.getMessage(),
						ex.getStackTraceString()
					});
				} else {
					message += String.valueOf(s.context);
				}
				messages.add(message);
			}
		}
		return messages;
	}

	/**
	 * Gets the post-install steps executed as part of the current results.
	 *
	 * @return The post-install steps.
	 */
	public List<Step> getSteps() {
		List<Step> steps = this.stepMap.values();
		steps.sort();
		return steps;
	}

	/**
	 * Generates a string representation of the post-install results.
	 *
	 * @return The string representation of the post-install results.
	 */
	override public String toString() {
		return Collection.mkString(getSteps(), '\n');
	}
}
