package org.camunda.bpm.getstarted.selfServiceRestaurant;

import java.util.logging.Logger;
import org.camunda.bpm.engine.delegate.DelegateExecution;
import org.camunda.bpm.engine.delegate.JavaDelegate;

public class ProcessRequestDelegate implements JavaDelegate {

    private final static Logger LOGGER = Logger.getLogger("SELF-Service");

    public void execute(DelegateExecution execution) throws Exception {
        LOGGER.info("Processing request by '" + execution.getVariable("customerId") + "'...");
    }
}
