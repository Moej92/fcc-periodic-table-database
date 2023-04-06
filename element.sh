#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=periodic_table -t --no-align -c"

## delete non existent element from elements and properties tables
# get the element
ATOMIC_1000=$($PSQL "SELECT atomic_number FROM properties WHERE atomic_number = 1000")
# if find element
if [[ $ATOMIC_1000 == 1000 ]]
then
  # drop foreign key constraint from properties table
  DROP_FK=$($PSQL "ALTER TABLE properties DROP CONSTRAINT properties_atomic_number_fkey")
  # add foregn key with "ON DELETE CASCADE"
  ADD_FK_ON_DELETE=$($PSQL "ALTER TABLE properties ADD FOREIGN KEY(atomic_number) REFERENCES elements(atomic_number) ON DELETE CASCADE")
  # delete the element row from properties and elements tables
  DELETED_ELEMENT=$($PSQL "DELETE FROM elements WHERE atomic_number = $ATOMIC_1000")
  echo $DELETED_ELEMENT
fi

## drop type column from properties table
# first check if column exist
TYPE_COLUMN=$($PSQL "SELECT column_name FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'type'")
if [[ $TYPE_COLUMN == type ]]
then
  # drop type column
  DROP=$($PSQL "ALTER TABLE properties DROP COLUMN type")
fi

GET_ELEMENT_INFO() {
  ATOMIC_NUMBER=$($PSQL "SELECT atomic_number FROM elements WHERE $1 = '$2'")
  if [[ -z $ATOMIC_NUMBER ]]
  then
    echo 'I could not find that element in the database.'
  else
    INFO=$($PSQL "SELECT atomic_number, name, symbol, type, atomic_mass, melting_point_celsius, boiling_point_celsius FROM elements FULL JOIN properties USING(atomic_number) FULL JOIN types USING(type_id) WHERE atomic_number = $ATOMIC_NUMBER")
    echo $INFO | while IFS='|' read AN NAME SYMBOL TYPE AM MPC BPC
    do
      echo "The element with atomic number $AN is $NAME ($SYMBOL). It's a $TYPE, with a mass of $AM amu. $NAME has a melting point of $MPC celsius and a boiling point of $BPC celsius."
    done 
  fi
}

if [[ -z $1 ]]
then
  echo Please provide an element as an argument.
else
  # if argument is atomic number
  if [[ $1 =~ ^[0-9]+$ ]]
  then
    GET_ELEMENT_INFO atomic_number $1
  # if argument is symbol
  elif [[ ${#1} -lt 3 ]]
  then
    GET_ELEMENT_INFO symbol $1
  # if argument is name
  elif [[ ${#1} -gt 2 ]]
  then 
    GET_ELEMENT_INFO name $1
  fi    
fi
