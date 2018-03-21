public class PostInstallResults {

	public enum StepStatus {
		SKIPPED, STARTED, SUCCESS, FAILURE
	}

	public class Step implements Comparable {

		public Integer sequence { get; private set; }
		public String name { get; private set; }
		public StepStatus status { get; private set; }
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

	public Integer count { get; private set; }
	private Map<String, Step> stepMap;
	public Boolean success { get; private set; }

	public PostInstallResults() {
		this.count = 0;
		this.stepMap = new Map<String, Step>();
		this.success = true;
	}

	public PostInstallResults beginStep(final String name) {
		stepMap.put(name, new Step(++this.count, name, StepStatus.STARTED, null));
		return this;
	}

	public PostInstallResults skipStep(final String name, final String reason) {
		stepMap.put(name, new Step(++this.count, name, StepStatus.SKIPPED, reason));
		return this;
	}

	public PostInstallResults endStepSuccess(final String name) {
		if (stepMap.containsKey(name)) {
			stepMap.put(name, stepMap.get(name).complete(true, null));
		} else {
			stepMap.put(name, new Step(++this.count, name, StepStatus.SUCCESS, null));
		}
		return this;
	}

	public PostInstallResults endStepSuccess(final String name, final Object context) {
		if (stepMap.containsKey(name)) {
			stepMap.put(name, stepMap.get(name).complete(true, context));
		} else {
			stepMap.put(name, new Step(++this.count, name, StepStatus.SUCCESS, context));
		}
		return this;
	}

	public PostInstallResults endStepFailure(final String name, final Exception ex) {
		if (stepMap.containsKey(name)) {
			stepMap.put(name, stepMap.get(name).complete(false, ex));
		} else {
			stepMap.put(name, new Step(++this.count, name, StepStatus.FAILURE, ex));
		}
		this.success = false;
		return this;
	}

	public PostInstallResults addResults(final PostInstallResults results) {
		if (results != null) {
			for (Step s : results.getSteps()) {
				this.stepMap.put(s.name, s.withSequence(++this.count));
			}
			this.success &= results.success;
		}
		return this;
	}

	public PostInstallResults addResults(final String name, final PostInstallResults results) {
		if (results != null) {
			for (Step s : results.getSteps()) {
				this.stepMap.put(name + ' -> ' + s.name, s.withSequence(++this.count));
			}
			this.success &= results.success;
		}
		return this;
	}

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

	public List<Step> getSteps() {
		List<Step> steps = this.stepMap.values();
		steps.sort();
		return steps;
	}

	override public String toString() {
		return Collection.mkString(getSteps(), '\n');
	}
}
