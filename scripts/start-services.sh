#!/bin/bash

# Run the Java application
java -jar /usr/local/lib/java-app.jar &

# Start Apache in the background
apache2ctl -D FOREGROUND



