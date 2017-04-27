def add_pci_women
	# load CSV File
	puts '==================================================='
	puts '                                                   '
	puts ' Select the type of data you would wish to Migrate '
	puts '                                                   '
	puts ' 1. PCI Child Data                                 '
	puts ' 2. PCI Women                                      '
	puts ' Press any key to Cancel/Exit                      '
	puts '                                                   '
	input = gets.chomp
	
	case input.to_i
		when 1
			puts '1 selected'
		when 2
			puts '2 selected'
		when 'C' || 'c'
			puts 'Cancel selected'
	end
	
end

add_pci_women