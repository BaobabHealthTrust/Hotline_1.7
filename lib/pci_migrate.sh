#!/bin/bash
# Purpose: To migrate PCI Data for children and women supplied by Village Reach
# Date: April 27th, 2017
# Author: Jacob Mziya (BHT Software Developer)
# ------------------------------------------------------

clear

echo
echo "PCI Data Migration initiated by [$USER on $HOSTNAME @ $(date +"%T")]"
sleep 2
echo "Starting to migrate PCI Data ..."
sleep 2
echo
echo
echo "Select which type of data you would wish to migrate"
echo "1. Child Data"
echo "2. Women Data"
echo "3. Both Child & Women Data (begins with child data then proceeds to women data)"
echo "4. Cancel/Exit"
echo
echo "Choose [1-4]?"
echo

echo

read INPUT

case "$INPUT" in
    1)
    #process child data
        echo "=============="
        echo "| CHILD DATA |"
        echo "=============="
        sleep 2
        echo "Processing PCI Child Data"
        sleep 2
        echo "Child PCI Data Migration starting..."
        sleep 3
        rails runner lib/add_pci_child_data.rb
    ;;

    2)
    # process women data
        echo "=============="
        echo "| WOMEN DATA |"
        echo "=============="
        sleep 2
        echo "Processing PCI Women Data"
        sleep 2
        echo "Women PCI Data Migration starting..."
        sleep 3
        rails runner lib/add_pci_women_data.rb
    ;;

    3)
    # process child data and then process women data
        #process child data
            echo "=============="
            echo "| CHILD DATA |"
            echo "=============="
            sleep 2
            echo "Processing PCI Child Data"
            sleep 2
            echo "Child PCI Data Migration starting..."
            sleep 3
            rails runner lib/add_pci_child_data.rb

            # process women data
                echo "=============="
                echo "| WOMEN DATA |"
                echo "=============="
                sleep 2
                echo "Processing PCI Women Data"
                sleep 2
                echo "Women PCI Data Migration starting..."
                sleep 3
                rails runner lib/add_pci_women_data.rb
    ;;

    4)
    # Cancel / Exit migration script
    echo "PCI Data Migration cancelled by $USER@$(date +"%T")";
    exit 0 ;;
esac


