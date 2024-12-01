#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=salon --tuples-only -c"
SERVICES_AVAILABLE=()
$($PSQL "SELECT * FROM services ORDER BY service_id") | while read SERVICE_ID BAR SERVICE_NAME
do
  $SERVICES_AVAILABLE+=($SERVICE_NAME)
done


MAIN_MENU() {
  if [[ $1 ]]
  then
    echo -e "$1"
  else
    echo -e "\n~~~ Welcome to the salon! ~~~\n"
  fi

  echo "$SERVICES_AVAILABLE" | while read SERVICE_NAME
  do
    echo "$SERVICE_ID) $SERVICE_NAME"
  done
  echo -e "\nChoose a service.\n"

  read SERVICE_ID_INPUT
  
  if [[ ! $SERVICE_ID_INPUT =~ ^[0-9]+$ ]]
  then
    MAIN_MENU "\n*** We don't offer that service.\n"
  fi
  
  CHOSEN_SERVICE_ID=$($PSQL "SELECT service_id FROM services WHERE service_id=$SERVICE_ID_INPUT")
  if [[ -z $CHOSEN_SERVICE_ID ]]
  then
    MAIN_MENU "\n*** We don't offer that service.\n"
  fi

  
}

MAIN_MENU