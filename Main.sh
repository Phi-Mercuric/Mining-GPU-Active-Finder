#!/bin/bash

output()
{
  	echo $(($(cat $1) + 1)) > $1
  	echo -ne "       `cat ~/.temp/site_count`\t|\t    `cat ~/.temp/calc_count`\t\t|\t  `cat ~/.temp/done_count`\r"
}

find_all_gpu_costs() 
{

	# preparing
	gpu=$1								 	# gpu name
	ID=$2
	locprof=$3								# gpu profits
	string=`echo $gpu| tr -s "_" "+"`		# gpu name formatted for ebay search

  	# Searching
	if [[ ${gpu: -1} == '+' ]]; then		# remove last character if it is a '+'
	  string=`echo $string| sed 's/.$//'`
	fi
	## site url for search, include exceptions for parts and broken cards, then manipulate site output into '\n' delimited list
	site=`echo 'https://www.ebay.com/sch/i.html?_from=R40&_trksid=p2334524.m570.l1313&_nkw='$string'+-parts+-non+-not+-box+-chip&_sacat=0&LH_TitleDesc=1&_ftrt=901&_ipg=25&LH_ItemCondition=1000%7C1500%7C2000%7C2500%7C3000&_dmd=1&_stpos=24201&LH_BIN=1&_odkw=+-parts+-non+-not+-box+-chip&_osacat=0&_sop=12&_ftrv=1&_sadis=15'`
	curl -s $site|tr -s "<>" "\n"|grep 'span class=s-item__price' -A 1| grep -v 'span' | tr -d '$,-' | grep '.' | cut -d '.' -f '1' > ~/.temp/MGAF-"$gpu"-costs.txt

	echo -ne "                                                        \r"							# reset line to reduce errors.
	output ~/.temp/site_count

	# Finding average cost
	gpuAv=0; gpuAvTrim1=0; gpuAvTrim2=0; costBotThreshold=0
	{ # Finding the price range that we will consider.
		# Finding average cost of all costs
		gpuAmt=0
		for cost in `cat ~/.temp/MGAF-"$gpu"-costs.txt`; do
			if [[ $gpuAmt != 0 ]]; then # Often first number is erroneous
				cost=`echo $cost| tr -d 'qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM"='`	# remove all words/letters
				gpuAv=$(( ( $gpuAv * $gpuAmt + $cost ) / ( $gpuAmt + 1 ) ))							# iteratively get average. Change this.
			fi
			gpuAmt=$(( $gpuAmt + 1 ))
		done

		# Find average cost without high. High first bc 1 high outlier can bring up av infinitely.
		gpuAmt=0
		for cost in `cat ~/.temp/MGAF-"$gpu"-costs.txt`; do
			if [[ $gpuAmt != 0 ]]; then # Often first number is erroneous
				cost=`echo $cost| tr -d 'qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM"='`
				if [[ $cost -lt $(( $gpuAv * 3 / 2 )) ]]; then 
					gpuAvTrim1=$(( ( $gpuAvTrim1 * $gpuAmt + $cost ) / ( $gpuAmt + 1 ) ))
				fi
			fi
			gpuAmt=$(( $gpuAmt + 1 ))
		done

		# Find average cost without low outliers.
		gpuAmt=0
		for cost in `cat ~/.temp/MGAF-"$gpu"-costs.txt`; do
			if [[ $gpuAmt != 0 ]]; then # Often first number is erroneous
				cost=`echo $cost| tr -d 'qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM"='`
				if [[ $cost -gt $(( $gpuAvTrim1 / 2 )) && $cost -lt $(( $gpuAv * 3 / 2 )) ]]; then	# prev eq doesn't delete high
					gpuAvTrim2=$(( ( $gpuAvTrim2 * $gpuAmt + $cost ) / ( $gpuAmt + 1 ) ))			# outliers, so it needs to be
				fi																					# done here.
			fi
			gpuAmt=$(( $gpuAmt + 1 ))
		done

		costBotThreshold=$(( $gpuAvTrim2 / 2 ))
	}

	gpuAmt=0; avCost=0
	for cost in `cat ~/.temp/MGAF-"$gpu"-costs.txt`; do
		# try to incorporate ASCII module thing instead of this & put in prev curl line thing
		cost=`echo $cost| tr -d 'qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM"='`
		if [[ "$cost" -gt "$costBotThreshold" ]]; then												# weed out high outliers
			if [[ "$(( $costBotThreshold * 4 ))" -gt "$cost" ]]; then								# weed out low outliers
				avCost=$(( ( $avCost * $gpuAmt + $cost ) / ( $gpuAmt + 1 ) ))						# iteratively get average
			fi
		fi
		gpuAmt=$(( $gpuAmt + 1 ))
	done
	output ~/.temp/calc_count

	# Outputting to file for later use
	profit=""
	if [[ ${locprof:0:1} == "-" ]]; then 
		profit="-"; 
		locprof=${locprof:1}; 
	fi

	while [[ "${locprof:0:1}" == "0" ]]; do locprof=${locprof:1}; done								# remove leading zeros

	if [[ ${profit:0:1} == "-" ]]; then 
		roi=$(( ( $avCost * 100 ) / $locprof ))
	fi
	if [[ $(( locprof % 100 )) -lt 10 ]]; then
		profit+="$(( locprof / 100 )).0$(( locprof % 100 ))"
	else
		profit+="$(( locprof / 100 )).$(( locprof % 100 ))"
	fi
	echo "
/- $gpu :
| link			 `echo $site|tr -d '"'`
| DBG:{ ID: $ID, GA: $gpuAv, GAT1: $gpuAvTrim1, GAT2: $gpuAvTrim2, CBT:$costBotThreshold, CTT: $(($costBotThreshold * 4)) }
| average cost		 \$$avCost
| average $/day		 \$$profit
| average ROI		 ~$roi days
| good/fake deals	 $good_deals
" >> ~/.temp/GPU_Info.txt
	output ~/.temp/done_count

}

gpu_ordered()
{
	#sorting by price
	rois=`cat ~/.temp/GPU_Info.txt| grep "ROI"| sort -u| tr -s "\n" "_"`		# list of gpus' rois in increasing order
	lineAmt=`echo $rois| tr -dc '_'| wc -c`													# number of gpus in list
	for digits in {1..5}; do
		for (( roiIter=1; roiIter<=$lineAmt; roiIter++ )); do									# From 1 to the total number of rois (iteration),
			roi=`echo $rois| cut -d "_" -f $roiIter| tr -dc "0-9"`								# get the roi of the current iteration, only take numbers, then
			if [[ `echo $roi| wc -c` == $digits ]]; then
				cat ~/.temp/GPU_Info.txt| grep -B 5 -A 1 "~$roi days"								# print all of the roi's corresponding info from GPU_Info.txt.
			fi
		done																					# This assumes there aren't duplicate rois, so the roi is like an ID
	done

	echo -e "\n\nHint: deal format is <price>:<roi in days>"

	# cleanup
	rm ~/.temp/MGAF-*
	rm ~/.temp/GPU_Info.txt
}



gpu_unordered()
{
	#sorting by name
	gpuNames=`cat ~/.temp/GPU_Info.txt| grep "/-"|sort -u|tr -d ': /-'| tr -s "\n" "|"`		# list of gpu names in alph. order
	lineAmt=`echo gpuNames| tr -dc '|'| wc -c`												# number of gpus

	for (( nameIter=1; nameIter<=$lineAmt; nameIter++ )); do								# From 1 to the total number of gpus (iteration),
		name=`echo gpuNames| cut -d "|" -f $nameIter`										# get the gpu name of the current iteration, then
		cat ~/.temp/GPU_Info.txt| grep -A 6 "/- $name "										# print all of the gpu's name's corresponding info
	done																					# from GPU_Info.txt.
	# cleanup
	rm ~/.temp/MGAF-*
	rm ~/.temp/GPU_Info.txt
}


database_update() 
{
	startT=`date +"%T"| tr -d ":"`

	# find if there is a database. If not, create it.
	bool=FALSE
	for folder in `ls ~/`; do
		if [[ $folder == "MGAF_Price_Archive" ]]; then
			bool=TRUE;
			break
		fi
	done
	if [[ $bool == FALSE ]]; then
		mkdir ~/MGAF_Price_Archive
	fi

	# create a new database file for the current time
	file=`date +"%y-%m-%d-%T"| cut --complement -d ":" -f 3`
	touch ~/MGAF_Price_Archive/history/$file
	gpu_unordered > ~/MGAF_Price_Archive/history/$file

	# output the time it took to update the database
	endT=`date +"%T"| tr -d ":"`
	echo "finished in `expr $endT - $startT` seconds"

	#cleanup
	rm ~/.temp/MGAF-*
	rm ~/.temp/GPU_Info.txt
}

{ # Entry point
	gpus=""; profitList=""								# GPU names ; GPU profits
	mkdir ~/.temp										# folder for temp gpu prices
	echo "" > ~/.temp/GPU_Info.txt						# file for outputting gpu info
	echo "|- Getting site information"
	gpus=`curl -s 'https://whattomine.com/gpus'| grep -A 1 -B 1 '</td>'| grep -B 2 '<td class="text-center">'| grep '</a>'| sed 's/<\/a>//'| tr -d '(*)'| sed 's/Unrestricted//'| tr -s " " "_"`
	profitList=`curl -s 'https://whattomine.com/gpus'| grep -A 1 '<td class="text-end table-">'| grep -v '<'| grep "[0..9]"| tr -d '.$'`

	echo -e "|--- Got site data\n|- Starting GPU calculations."
	echo -e "|--- Got site\t|\tCalculated\t|\tFinished";

	# initialize global variables in from of files. These are used to keep track of the progress of the program
	echo "0" > ~/.temp/site_count; echo "0" > ~/.temp/calc_count; echo "0" > ~/.temp/done_count

	ID=0												# GPU ID
	for gpu in $gpus; do
		ID=$(( $ID + 1 ))
		locprof=`echo $profitList| cut -d " " -f $ID`	# GPU profit corresponding to ID
		find_all_gpu_costs $gpu $ID $locprof &			# find all data for corresponding gpu
	done
	wait												# wait for threads to catch up

	rm ~/.temp/site_count ~/.temp/calc_count ~/.temp/done_count
	while getopts ":udo" opt; do
		case $opt in
			u)
				echo -e "\nstarting unordered GPU finder"; gpu_unordered
				;;
			d)
				echo -e "\nupdating database"; database_update
				;;
			o)
				echo -e "\nstarting ordered GPU finder";
				echo " ";
				gpu_ordered;;
			/?)
				echo -e "\nstarting unordered GPU finder"; gpu_unordered
				;;
		esac
	done
}