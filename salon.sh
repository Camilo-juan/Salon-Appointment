#!/bin/bash

# Definir la variable PSQL para conectar a la base de datos 
PSQL="psql --username=freecodecamp --dbname=salon -t --no-align -c"

# Mensaje de bienvenida
echo "~~~~~ MY SALON ~~~~~"
echo "Welcome to My Salon, how can I help you?"

# Mostrar la lista de servicios al inicio
SERVICES="$($PSQL "SELECT service_id, name FROM services;")"
echo "$SERVICES" | while IFS="|" read SERVICE_ID NAME; do
  echo "$SERVICE_ID) $NAME"
done

# Función para mostrar los servicios (para reutilizar en caso de opción inválida)
show_services() {
  SERVICES="$($PSQL "SELECT service_id, name FROM services;")"
  echo "$SERVICES" | while IFS="|" read SERVICE_ID NAME; do
    echo "$SERVICE_ID) $NAME"
  done
}

# Bucle para solicitar un servicio
while true; do 
  # Leer la selección del usuario
  read SERVICE_ID_SELECTED
  
  # Verificar si el servicio existe
  SERVICE_EXISTS="$($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED;")"

  if [[ -z $SERVICE_EXISTS ]]; then
    # Mensaje de error y mostrar la lista de servicios si la selección es inválida
    echo "I could not find that service. What would you like today?"
    show_services
  else
    # Confirmación de selección válida y salir del bucle
    echo "You have selected the service: $SERVICE_EXISTS"
    break
  fi
done

# Solicitud de número de teléfono
echo "What's your phone number??"

# Leer la entrada (número de teléfono del usuario)
read CUSTOMER_PHONE

# Verificar si el número del usuario está en la base de datos
PHONE_EXIST="$($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE';")"

if [[ -z $PHONE_EXIST ]]; then
    # Mensaje que indica que no hay registro para el número de teléfono
    echo "I don't have a record for that phone number, what's your name?"
    read CUSTOMER_NAME

    # Insertar el nuevo cliente en la tabla customers
    INSERT_RESULT="$($PSQL "INSERT INTO customers (name, phone) VALUES ('$CUSTOMER_NAME', '$CUSTOMER_PHONE') RETURNING customer_id;")"
    
    # Recuperar el customer_id del cliente recién agregado
    CUSTOMER_ID=$(echo "$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE';")")

else
    # Si el número de teléfono existe, recupera el customer_id
    CUSTOMER_ID=$(echo "$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE';")")
    
    # Recuperar el nombre del cliente existente
    CUSTOMER_NAME="$($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE';")"
fi

# Solicitar la hora para el servicio
while true; do
  echo "What time would you like your $SERVICE_EXISTS, $CUSTOMER_NAME? (HH:MM)"
  read SERVICE_TIME
  
  
  if [[ $? -eq 0 ]]; then
    break  # Salir del bucle si el formato es válido
  else
    echo "Invalid time format. Please enter the time in HH:MM format."
  fi
done

# Asegurarte de que CUSTOMER_ID y SERVICE_ID_SELECTED son válidos antes de insertarlos
echo "Debug: Customer ID is $CUSTOMER_ID"
echo "Debug: Service ID is $SERVICE_ID_SELECTED"
echo "Debug: Executing SQL - INSERT INTO appointments (customer_id, service_id, time) VALUES ($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME') RETURNING appointment_id;"

# Insertar en la tabla appointments
INSERT_APPOINTMENT_RESULT="$($PSQL "INSERT INTO appointments (customer_id, service_id, time) VALUES ($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME') RETURNING appointment_id;")"

# Confirmar que la cita fue programada
if [[ $? -eq 0 ]]; then
  echo "I have put you down for a $SERVICE_EXISTS at $SERVICE_TIME, $CUSTOMER_NAME."
else
  echo "There was an error scheduling your appointment."
fi
