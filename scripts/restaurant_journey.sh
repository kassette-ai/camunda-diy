#!/bin/bash


CAMUDA_HOST="${CAMUNDA_HOST:=localhost}"


size_of_the_queue=0 # start from 0 second queue
MEAL_PREP_TIME=0 # no meal at the start
MAX_WAITING_CUSTOMERS=10


CAMUNDA_REST_URL="http://${CAMUNDA_HOST}:8090/engine-rest"
CURL='curl -s -H "Content-Type: application/json"'
NN=0
while true; do
	customer="customer${NN}"
        RANDOM_CHANCE=$((RANDOM%100)) # some randomness for droping early from a cycle
	WAITING_CUSTOMERS=`jobs -r | wc -l | tr -d " "`
        while [[ $WAITING_CUSTOMERS -gt $MAX_WAITING_CUSTOMERS ]]; do
		sleep 5
		echo "Too many customers in the shop, waiting outside, COVID: $WAITING_CUSTOMERS"
		WAITING_CUSTOMERS=`jobs -r | wc -l | tr -d " "`
	done
	echo "CUSTOMER: ${customer}  --- walking into a restaurant"
	PROCESS_INSTANCE_ID=`curl -s -H "Content-Type: application/json" $CAMUNDA_REST_URL/process-definition/key/guest_food_consumption/start \
		-X POST -d "{\"businessKey\" : \"${customer}\" }"|jq -r '.id'`

	if [ $RANDOM_CHANCE -lt 10 ];
	then
		sleep 30 
                let NN=$NN+1 
		echo "CUSTOMER: ${customer}  --- can't wait, I am leaving"
		continue  # can't wait, I am leaving
	fi
		

	echo "CUSTOMER: ${customer}  --- Getting task id which should be completed manually"
	TASK_ID=`curl -s -H "Content-Type: application/json" "$CAMUNDA_REST_URL/task?processInstanceId=${PROCESS_INSTANCE_ID}&name=wait+for+turn"| jq -r '.[0].id'`
	echo "CUSTOMER: ${customer}  --- Completing task ${TASK_ID}"
	curl -s -H "Content-Type: application/json" "$CAMUNDA_REST_URL/task/${TASK_ID}/complete" -X POST
	echo "CUSTOMER: ${customer}  --- placing an order - takes 30 seconds"
	sleep 30 # it takes 1 minute to palce an order
	echo "CUSTOMER: ${customer}  --- starting employee order processing activiti"
        curl -s -H "Content-Type: application/json" $CAMUNDA_REST_URL/message \
		-X POST -d "{\"messageName\" : \"Message_guest_order_placed\", \"businessKey\" : \"${customer}\"}"


	range=$((1500 - 300 + 1))
	MEAL_PREP_TIME=$((RANDOM % range + 300))
	echo "CUSTOMER: ${customer}  --- inform chef and preptime will take $MEAL_PREP_TIME"
        curl -s -H "Content-Type: application/json" $CAMUNDA_REST_URL/message \
		-X POST -d "{\"messageName\" : \"Message_employee_request_meal\", \"businessKey\" : \"${customer}\", 
	                \"processVariables\": { \"chefPrepTime\": { 
			\"value\": \"PT${MEAL_PREP_TIME}S\", \"type\": \"String\" } } }"
	if [ $RANDOM_CHANCE -gt 10 ] && [ $RANDOM_CHANCE -lt 20 ];
	then
		sleep 30 
                let NN=$NN+1 
		echo "CUSTOMER: ${customer}  --- can't wait, I am leaving, just feed it to pigs"
		continue  # can't wait, I am leaving
	fi

        ( sleep $MEAL_PREP_TIME && curl -s -H "Content-Type: application/json" $CAMUNDA_REST_URL/message \
		-X POST -d "{\"messageName\" : \"Message_chef_meal_ready\", \"businessKey\" : \"${customer}\"}" && \
		curl -s -H "Content-Type: application/json" $CAMUNDA_REST_URL/message \
		-X POST -d "{\"messageName\" : \"Message_employee_meal_ready\", \"businessKey\" : \"${customer}\"}" \
		echo "CUSTOMER: ${customer}  --- Food ready and journey complete"
	) &
        let NN=$NN+1 
done
