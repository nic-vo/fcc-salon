#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=salon --tuples-only -c"

declare -a SERVICES_NAME_ARRAY
declare -a SERVICES_ID_ARRAY
while read S_ID BAR S_NAME; do
  echo "$S_ID) $S_NAME"
  SERVICES_ID_ARRAY+=( $S_ID )
  SERVICES_NAME_ARRAY+=( "$S_NAME" )
done < <(echo "$($PSQL "SELECT service_id,name FROM services ORDER BY service_id")")

NL_ECHO() {
  local input="$1"
  if [[ $input ]]
  then
    echo -e "\n$input"
  fi
}

NL_ECHO "~~~ Welcome to the salon! ~~~"

MAIN_MENU() {
  local RESET_MESSAGE="$1"
  if [[ $RESET_MESSAGE ]]
  then
    NL_ECHO "$RESET_MESSAGE"
  else
    NL_ECHO "Choose a service."
  fi

  for I in "${!SERVICES_NAME_ARRAY[@]}"; do
    echo "${SERVICES_ID_ARRAY[$I]}) ${SERVICES_NAME_ARRAY[$I]}"
  done

  read SERVICE_ID_SELECTED
  S_ID_ZERO_I=$(($SERVICE_ID_SELECTED - 1))
  
  if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ || $S_ID_ZERO_I -lt 0 || -z "${SERVICES_NAME_ARRAY[$S_ID_ZERO_I]}" || -z "${SERVICES_ID_ARRAY[$S_ID_ZERO_I]}" ]]
  then
    MAIN_MENU "I could not find that service. What would you like today?"
  else
    echo Cool!
  fi
  
  if [[ $ADD_APPT_RESULT ]]
  then
    return 0
  fi

  NL_ECHO "What's your phone number?"
  read CUSTOMER_PHONE

  CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")
  if [[ -z $CUSTOMER_ID ]]
  then
    NL_ECHO "What's your name?"
    read CUSTOMER_NAME
    INSERT_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers(name,phone) VALUES('$CUSTOMER_NAME', '$CUSTOMER_PHONE')")
    if [[ $INSERT_CUSTOMER_RESULT != 'INSERT 0 1' ]]
    then
      MAIN_MENU "$(NL_ECHO "There was an error processing your info.")"
    fi
  fi
  CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")

  if [[ -z $CUSTOMER_NAME ]]
  then
    CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE customer_id=$CUSTOMER_ID")
  fi
  NL_ECHO "$(echo "Hello, $CUSTOMER_NAME!" | sed -r 's/, +/, /g')"

  NL_ECHO "At what time would you like to do this?"
  read SERVICE_TIME
  ADD_APPT_RESULT=$($PSQL "INSERT INTO appointments(service_id,customer_id,time) VALUES(${SERVICES_ID_ARRAY[$S_ID_ZERO_I]}, $CUSTOMER_ID, '$SERVICE_TIME')")

  while [[ $ADD_APPT_RESULT != 'INSERT 0 1' ]];
  do
    NL_ECHO "Try another time."
    read SERVICE_TIME
    ADD_APPT_RESULT=$($PSQL "INSERT INTO appointments(service_id,customer_id,time) VALUES(${SERVICES_ID_ARRAY[$S_ID_ZERO_I]}, $CUSTOMER_ID, '$SERVICE_TIME')")
  done

  echo $(echo "I have put you down for a ${SERVICES_NAME_ARRAY[$S_ID_ZERO_I]} at $SERVICE_TIME, $CUSTOMER_NAME.") | sed -r 's/, +/, /g'
  return 0
}

MAIN_MENU