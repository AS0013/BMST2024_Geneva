/**
* Name: TramLines
* Based on the internal empty template. 
* Authors : Atta_Elisabetta
* Tags: 
*/


model TramLines


global {
	
	file shape_file_tram_lines <- file("../includes/TPG_LIGNES.shp");
	file shape_file_tram_stops <- file("../includes/TPG_ARRETS.shp");
	
	geometry shape <- envelope(shape_file_tram_lines);
	graph the_graph;
	float step <- 60 #s;
	
	
    list<string> tram_stop_names_towards_cern <-
    ["Grand-Lancy, Palettes",
    "Grand-Lancy, Pontets",
    "Plan-Les-Ouates, Trèfle-Blanc",
    "Lancy-Bachet, Gare",
    "Grand-Lancy, De-Staël",
    "Carouge Ge, Rondeau",
    "Carouge Ge, Ancienne",
    "Carouge Ge, Marché",
    "Carouge Ge, Armes",
    "Genève, Blanche",
    "Genève, Augustins",
    "Genève, Pont-D'Arve",
    "Genève, Plainpalais",
    "Genève, Place De Neuve",
    "Genève, Bel-Air",
    "Genève, Coutance",
    "Genève, Gare Cornavin",
    "Genève, Lyon",
    "Genève, Poterie",
    "Genève, Servette",
    "Genève, Vieusseux",
    "Vernier, Bouchet",
    "Vernier, Balexert",
    "Vernier, Avanchet",
    "Vernier, Blandonnet",
    "Meyrin, Jardin-Alpin-Vivarium",
    "Meyrin, Bois-Du-Lan",
    "Meyrin, Village",
    "Meyrin, Hôpital De La Tour",
    "Meyrin, Maisonnex",
    "Meyrin, Cern"];
    
 
 
  	list<stop> stop_list;
  	stop Tram_Terminal_1; //palletes
  	stop Tram_Terminal_2; // CERN
  	
  	//parameters we are experimenting with
  	float global_speed <- 23 #km/#h;
  	int number_of_passengers <- 200;
  	int Tram_capacity <- 50;
  	bool create_another_tram_in_opposite_direction <- false;
  	
  	int passenger_creating_interval <- 60; // hour
  	int passengers_per_interval <- 0; // rnd(0,10); // no. of passengers to create per interval
  	int passenger_count <- 0;
	
	init {
		
		// creating stop and tram_line from the shape files
		create stop from: shape_file_tram_stops with: [name::(read("NOM_ARRET"))];
		create tram_line from: shape_file_tram_lines with:[LIGNE::string(read("LIGNE"))];
		
		// deleting the tramlines that ARE NOT tram line 18
		
		loop tramline over:tram_line{
			if tramline.LIGNE != "18"{
				tramline.color <- #black;
			}
		}
		
		// create edge graph for tramline, so the tram will travel on it.
		the_graph <- as_edge_graph(tram_line);
		
		
		// just lower casing the list of stops we have	
		loop i from: 0 to: length(tram_stop_names_towards_cern) -1{
			tram_stop_names_towards_cern[i] <- lower_case(tram_stop_names_towards_cern[i]);
		}

		
		//deleting the stops that are not on the line 18
		loop Stop over: stop{
			if not(lower_case(Stop.name) in (tram_stop_names_towards_cern)){
				ask Stop{
					do die;
				}
			}
		}
		
		// make a list of type stop following the order of the list tram_stop_names_towards_cern
		
		loop i from: 0 to: length(tram_stop_names_towards_cern) -1 {
			string stop_name <- tram_stop_names_towards_cern[i];
			stop corresponding_stop;
			
			//find the stop that matches the stop name
			loop Stop over: stop{
				if (lower_case(Stop.name) = lower_case(stop_name)){
					corresponding_stop <- Stop;
					break;
				}
			}
			
			//add the found stop to stop_list
			if (corresponding_stop != nil){
				stop_list << corresponding_stop;
				
			}
		}
		
		Tram_Terminal_1 <- stop_list[0]; // palletes
		Tram_Terminal_2 <- stop_list[length(stop_list) - 1]; // CERN
		
		
		//create a tram 18
		 
		create tram_18_towards_cern number: 1{
			stop first_stop_towards_cern;
			stop last_stop_towards_cern;
			
			
			loop Stop over: stop{
				if (lower_case(Stop.name) = (tram_stop_names_towards_cern[0])){
					first_stop_towards_cern <- Stop;
					break;
				}
			}
			
			loop Stop over: stop{
				if (lower_case(Stop.name) = (tram_stop_names_towards_cern[length(tram_stop_names_towards_cern) - 1])){
					last_stop_towards_cern <- Stop;
					break;
				}
			}
			
			location <- any_location_in(first_stop_towards_cern);
			target <- nil;
			target_index <- 0;
			speed <- global_speed;
			Terminal_1 <- first_stop_towards_cern;
			Terminal_2 <- last_stop_towards_cern;
			Direction <- last_stop_towards_cern;
			moving_towards_cern <- true;
			
		}
		
		//create another tram going opposite direction
		if (create_another_tram_in_opposite_direction){
		create tram_18_towards_cern number: 1{
			stop first_stop_towards_cern;
			stop last_stop_towards_cern;
			
			
			loop Stop over: stop{
				if (lower_case(Stop.name) = (tram_stop_names_towards_cern[0])){
					last_stop_towards_cern <- Stop;
					break;
				}
			}
			
			loop Stop over: stop{
				if (lower_case(Stop.name) = (tram_stop_names_towards_cern[length(tram_stop_names_towards_cern) - 1])){
					first_stop_towards_cern <- Stop;
					break;
				}
			}
			
			location <- any_location_in(first_stop_towards_cern);
			target <- nil;
			target_index <- length(tram_stop_names_towards_cern);
			speed <- global_speed;
			Terminal_1 <- first_stop_towards_cern;
			Terminal_2 <- last_stop_towards_cern;
			Direction <- last_stop_towards_cern;
			moving_towards_cern <- false;
			
		}
		}
		
		//create passengers with random start positions and destination position
		loop i from: 1 to: number_of_passengers{
			stop start_stop1;
			stop destination_stop1; 
			stop Toward;
			// start and destination are randomly picked from the list tram_stop_names_towards_cern
			
			
			int start_index <- rnd(1,length(stop_list)-1);
			start_stop1 <- stop_list[start_index];
			int destination_index;
			
			bool not_found <- true;
			
			loop while: not_found{
				destination_index <- rnd(1,length(stop_list)-1);
				if destination_index != start_index {
					not_found <- false;
				}
			}
			
			
			destination_stop1 <- stop_list[destination_index];
			
	
			
			// Determining direction based on whether the destination index comes before after the start_index
			if (destination_index <= start_index){
				// logic for passengers direction
				Toward <- Tram_Terminal_1;
			}else{
				Toward <- Tram_Terminal_2;
			}
			 
			 
			//then actually create the passenger with the chosen start and destination
			create passenger{
				start_stop <- start_stop1;
				destination_stop <- destination_stop1;
				location <- any_location_in(start_stop);
				speed <- global_speed;
				Direction <- Toward;
		}
		passenger_count <- passenger_count + 1;
			
		}
		
		
	}
}


species tram_18_towards_cern skills:[moving]{
	rgb color <- #red;
	point target;
	int target_index;
	int passenger_capacity <- Tram_capacity;
	int current_passengers <- 0;
	stop Terminal_1;
	stop Terminal_2;
	stop Direction;
	bool moving_towards_cern;
	
	
	
	reflex update_target when: target = nil{
		if(moving_towards_cern){
			Direction <- Terminal_2;
			target_index <- target_index + 1;
			if (target_index = length(tram_stop_names_towards_cern)){
				moving_towards_cern <- false;
				target_index <- target_index - 1;
			}
		}
		else{
			Direction <- Terminal_1;
			target_index <- target_index - 1;
			if (target_index = 0){
				moving_towards_cern <- true;
				target_index <- target_index + 1;
			}
		}
		
		stop next_stop;
		
		loop Stop over: stop{
			if (lower_case(Stop.name) = (tram_stop_names_towards_cern[target_index])){
				next_stop <- Stop;
				break;
			}
		}
		
		target <- any_location_in(next_stop);
		
	}

	
	reflex move{
	
		do goto(target:target) on: the_graph;
		if location = target{
			
			target<-nil;
			/* 
			loop i from: 0 to: 10000{
				//stalling, to "simulate"  a tram stopping at each stop for  a moment
			}
			* 
			*/
		}
	}
	reflex full_capacity{
		if current_passengers = passenger_capacity{
			color <- #yellow;
			
		} else{
			color <- #red;
		}
	}
	
	aspect base{
		draw circle(150#m) color:color;
	}
}



species passenger skills:[moving] {
	
	stop start_stop;
	stop destination_stop;
	bool reached_destination <- false;
	bool is_on_tram <- false;
	rgb color <- #blue;
	float boarding_time <- 0.0;
	float start_time <- time; 
	stop Direction;
	tram_18_towards_cern my_tram;
	
	
 	//passengers choosing to boards tram if tram going towards destination
 	
	reflex move {
		if not reached_destination {
			if not is_on_tram{
				loop Tram over: tram_18_towards_cern{
					//check if the tram is moving towards passengers destination
					stop next_stop;
					if (Tram.moving_towards_cern){
						next_stop <- Tram.Terminal_2;
					}else{
						next_stop <- Tram.Terminal_1;
					}
					
					bool moving_towards_destination <- (Tram.moving_towards_cern and Direction = Tram.Terminal_2) or (not Tram.moving_towards_cern and Direction = Tram.Terminal_1);
					
					if moving_towards_destination and Tram.current_passengers < Tram.passenger_capacity and Tram.location = any_location_in(start_stop){
						is_on_tram <- true;
						my_tram <- Tram;
						my_tram.current_passengers <- my_tram.current_passengers + 1;
						boarding_time <- time;
						float waiting_time <-  boarding_time - start_time ;
						write "Passenger waited " + waiting_time + " for the tram";
                        break; // Exit the loop once the tram is found
					}
				}
			}
			else{
				
				if my_tram.location = any_location_in(destination_stop){
					reached_destination <- true;
					is_on_tram <- false;
					my_tram.current_passengers <- my_tram.current_passengers - 1;
					float travel_time <- time - boarding_time;
					write "passenger spent " + travel_time + " unit time travelling on tram to get to destination";
					do die;
				}
				else{
						do goto(target: any_location_in(my_tram.target)) on: the_graph;
							
					}
			}
		}
	}

	
	aspect base{
		draw circle(50#m) color: color;
	}
	
}


species tram_line  {
	string LIGNE;
	rgb color <- #orange ;
	
	aspect base {
		draw shape color: color;
	}
}

species stop {
	rgb color <- #black ;
	string name;
	aspect base {
		draw square(40) color: color;
	}
}

experiment road_traffic type: gui {
	 /*
	reflex when:((cycle mod passenger_creating_interval = 0) and cycle != 0) {
		loop i from: 0 to: passengers_per_interval {
			stop start_stop1;
			stop destination_stop1; 
			stop Toward;
			// start and destination are randomly picked from the list tram_stop_names_towards_cern
			
			
			int start_index <- rnd(0,length(stop_list)-1);
			start_stop1 <- stop_list[start_index];
			
			int destination_index;
			
			bool not_found <- true;
			
			loop while: not_found{
				destination_index <- rnd(0,length(stop_list)-1);
				if destination_index != start_index {
					not_found <- false;
				}
			}
			destination_stop1 <- stop_list[destination_index];
			
	
			
			// Determining direction based on whether the destination index comes before after the start_index
			if (destination_index <= start_index){
				// logic for passengers direction
				Toward <- Tram_Terminal_1;
			}else{
				Toward <- Tram_Terminal_2;
			}
			 
			 
			//then actually create the passenger with the chosen start and destination
			create passenger{
				start_stop <- start_stop1;
				destination_stop <- destination_stop1;
				location <- any_location_in(start_stop);
				speed <- global_speed;
				Direction <- Toward;
		}
		passenger_count <- passenger_count + 1;	
		}
		write "passenger_count " + passenger_count;
		
	}
	* 
	*/
	
		
	output {
		display city_display type:3d {
			species tram_line aspect: base;
			species stop aspect: base;
			species tram_18_towards_cern aspect: base;
			species passenger aspect: base;
			
		}
		
		
	}
	
	
	
	
	
}