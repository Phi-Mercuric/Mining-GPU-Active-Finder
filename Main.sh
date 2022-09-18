#!/bin/bash

find_all_gpu_costs() 
{
	# preparing
	gpu=$1
	temp=$2
	locprof=$3
	string=`echo $gpu| tr -s "_" "+"`

	if [[ ${gpu: -1} == '+' ]]; then
		string=`echo $string| sed 's/.$//'`
	fi
	
	site=`echo 'https://www.ebay.com/sch/i.html?_from=R40&_trksid=p2334524.m570.l1313&_nkw='$string'+-parts+-non+-not+-box+-chip&_sacat=0&LH_TitleDesc=1&_ftrt=901&_ipg=25&LH_ItemCondition=1000%7C1500%7C2000%7C2500%7C3000&_dmd=1&_stpos=24201&LH_BIN=1&_odkw=+-parts+-non+-not+-box+-chip&_osacat=0&_sop=12&_ftrv=1&_sadis=15'`

	# site things
	
	# this is due to some odd errors when using variables whose root causes illuded base debugging. Fix this.
	curl -s $site|tr -s "<>" "\n"|grep 'span class=s-item__price' -A 1| grep -v 'span' | tr -d '$,-' | grep '.' | cut -d '.' -f '1' > $gpu-costs.txt
	
	echo $(($(cat site_count) + 1)) > site_count
	echo -ne "                                                        \r"
	echo -ne "       `cat site_count`\t|\t    `cat calc_count`\t\t|\t  `cat done_count`\r"
	
	# Finding average cost
	gpuAv=0
	gpuAvTrim1=0
	gpuAvTrim2=0
	costBotThreshold=0
	{ # Finding the price range that we will consider.

		# Finding average cost of all costs
		gpuAmt=0
		for cost in `cat "$gpu-costs.txt"`; do
			if [[ $gpuAmt != 0 ]]; then # Often first number is erronious
				cost=`echo $cost| tr -d 'qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM"='`
				gpuAv=$(( ( $gpuAv * $gpuAmt + $cost ) / ( $gpuAmt + 1 ) ))
			fi
			gpuAmt=$(( $gpuAmt + 1 ))
		done

		# Find average cost without high. High first bc 1 high outlier can bring up av infinately.
		gpuAmt=0
		for cost in `cat "$gpu-costs.txt"`; do
			if [[ $gpuAmt != 0 ]]; then # Often first number is erronious
				cost=`echo $cost| tr -d 'qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM"='`
				if [[ $cost -lt $(( $gpuAv * 3 / 2 )) ]]; then 
					gpuAvTrim1=$(( ( $gpuAvTrim1 * $gpuAmt + $cost ) / ( $gpuAmt + 1 ) ))
				fi
			fi
			gpuAmt=$(( $gpuAmt + 1 ))
		done

		# Find average cost without low outliers.
		gpuAmt=0
		for cost in `cat "$gpu-costs.txt"`; do
			if [[ $gpuAmt != 0 ]]; then # Often first number is erronious
				cost=`echo $cost| tr -d 'qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM"='`
				if [[ $cost -gt $(( $gpuAvTrim1 / 2 )) && $cost -lt $(( $gpuAv * 3 / 2 )) ]]; then 	# prev eq doesn't delete high 
					gpuAvTrim2=$(( ( $gpuAvTrim2 * $gpuAmt + $cost ) / ( $gpuAmt + 1 ) ))			# outliers, so it needs to be
				fi
			fi
			gpuAmt=$(( $gpuAmt + 1 ))
		done

		costBotThreshold=$(( $gpuAvTrim2 / 2 ))
	}

	gpuAmt=0
	avCost=0
	for cost in `cat "$gpu-costs.txt"`; do
		# try to incorperate ASCII module thing instead of this & put in prev curl line thing ( not on linux rn )
		cost=`echo $cost| tr -d 'qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM"='`
		if [[ "$cost" -gt "$costBotThreshold" ]]; then
			if [[ "$(( $costBotThreshold * 6 ))" -gt "$cost" ]]; then
				avCost=$(( ( $avCost * $gpuAmt + $cost ) / ( $gpuAmt + 1 ) ))
			fi
		fi
		gpuAmt=$(( $gpuAmt + 1 ))
	done
	
	echo $(($(cat calc_count) + 1)) > calc_count
	echo -ne "       `cat site_count`\t|\t    `cat calc_count`\t\t|\t  `cat done_count`\r"	

	# cutting off leading 0s to prevent error (I.E. 5 / 02.78 )
	while [[ "${locprof:0:1}" == "0" ]]; do
		locprof=${locprof:1}
	done
	
	# finding good deals
	#good_deals=""
	#gpuAmt=0
	#for cost in `cat "$gpu-costs.txt"`; do
	#	cost=`echo $cost| tr -d 'qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM"='`
	#	if [[ "$gpuAmt" == "0" ]]; then
	#		costBotThreshold=$(( $cost / 3 ))
	#	fi
	#	if [[ "$cost" -gt "$costBotThreshold" ]]; then
	#		if [[ $(( avCost * 9 / 10 )) -gt $cost ]]; then
	#			good_deals+="\$$cost:$(( $cost * 100 / $locprof ))d, "
	#		fi
	#	fi
	#	gpuAmt=$(( $gpuAmt + 1 ))
	#done
	
	rm "$gpu-costs.txt"

	roi=$(( ( $avCost * 100 ) / $locprof ))
	
	
	echo "  
/- $gpu :
| link			 `echo $site|tr -d '"'`
| DBG:{ ID: $temp, GA: $gpuAv, GAT1: $gpuAvTrim1, GAT2: $gpuAvTrim2, CBT:$costBotThreshold }
| average cost		 \$$avCost
| average $/day		 \$$(( locprof / 100 )).$(( locprof % 100 )) 
| average ROI		 ~$roi days
| good/fake deals	 $good_deals
" >> Best_GPUs.txt
	
	echo $(($(cat done_count) + 1)) > done_count
	echo -ne "       `cat site_count`\t|\t    `cat calc_count`\t\t|\t  `cat done_count`\r"
}

gpu_ordered()
{
	
	gpus=" "
	prof=" "
	output=" "
	
	main () 
	{

		echo "|- Getting site information"
		
		echo " " > Best_GPUs.txt
		
		gpus=`curl -s 'https://whattomine.com/gpus'| grep -A 1 -B 1 '</td>'| grep -B 2 '<td class="text-center">'| grep '</a>'| sed 's/<\/a>//'| tr -d '(*)'| sed 's/Unrestricted//'| tr -s " " "_"`
		
		prof=`curl -s 'https://whattomine.com/gpus'| grep -A 1 '<td class="text-end table-">'| grep -v '<'| grep -v '-'| tr -d '.$'`
		
		echo "|--- Got site data\n|- starting GPU calculations."
		echo "0" > site_count
		echo "0" > calc_count
		echo "0" > done_count
		echo -ne "|--- Got site\t|\tCalculed\t|\tFinished\n\n";
		temp=0
		for gpu in $gpus; do
			temp=$(( $temp + 1 ))
			locprof=`echo $prof| cut -d " " -f $temp` 
			find_all_gpu_costs $gpu $temp $locprof &
		done 
		wait
		
		rm site_count calc_count done_count		

		#sorting by price
		rois=`cat Best_GPUs.txt| grep "ROI"| sort -u| tr -s "\n" "_"`
		lines=`echo $rois| tr -dc '_'| wc -c`
		
		for (( roiIt=1; roiIt<=$lines; roiIt++ )); do
			s=`echo $rois| cut -d "_" -f $roiIt| tr -dc "0-9"`
			cat Best_GPUs.txt| grep -B 5 -A 1 "~$s days"
		done

		echo -e "\n\nHint: deal format is <price>:<roi in days>"
		
		rm Best_GPUs.txt
		
	}
	
	main

}



gpu_unordered()
{
	# now alphabetical for database purposes

	gpus=" "
	prof=" "
	output=""
	
	main () 
	{

		echo "Starting..."
		
		echo " " > Best_GPUs.txt
		
		gpus=`curl -s 'https://whattomine.com/gpus'| grep -A 1 -B 1 '</td>'| grep -B 2 '<td class="text-center">'| grep '</a>'| sed 's/<\/a>//'| tr -d '(*)'| sed 's/Unrestricted//'| tr -s " " "_"`
		
		prof=`curl -s 'https://whattomine.com/gpus'| grep -A 1 '<td class="text-end table-">'| grep -v '<'| grep -v '-'| tr -d '.$'`
		
		echo ". . ."
		
		temp=0
		
		for gpu in $gpus; do
			temp=$(( $temp + 1 ))
			locprof=`echo $prof| cut -d " " -f $temp` 
			find_all_gpu_costs $gpu $temp $locprof &
		done
		
		wait
		
		#sorting by price
		
		rois=`cat Best_GPUs.txt| grep "/-"|sort -u|tr -d ': /-'| tr -s "\n" "|"`
		lines=`echo $rois| tr -dc '|'| wc -c`
		
		for (( roiIt=1; roiIt<=$lines; roiIt++ )); do
			s=`echo $rois| cut -d "|" -f $roiIt`
			cat Best_GPUs.txt| grep -A 6 "/- $s "
		done

		rm Best_GPUs.txt
		
	}
	
	main
	
}


database_update() 
{ 
	_bool=true
	for folder in `ls ~/`; do
		if [[ $folder == "price_archive" ]]; then
			_bool=false
			break
		fi
	done

	if [[ "$_bool" == "true" ]]; then
		mkdir ~/price_archive
		mkdir ~/price_archive/history
		mkdir ~/price_archive/history/cleaned
	fi

	startT=`date +"%T"| tr -d ":"`
	
	file=`date +"%y-%m-%d-%T"| cut --complement -d ":" -f 3`
	
	
	touch ~/price_archive/history/$file

	gpu_unordered > ~/price_archive/history/$file

	endT=`date +"%T"| tr -d ":"`
	
	echo "finished in `expr $endT - $startT` seconds"
}
	
while getopts ":udo" opt; do
	case $opt in
		u)
			echo "starting unordered GPU finder"; gpu_unordered
			;;
		d)
			echo "updating database"; database_update
			;;
		o)
			echo "starting ordered GPU finder";
			echo " ";
			gpu_ordered;;
		\?)
			echo -e "-o	GPU cards orded by ROI\n-u	GPU cards unordered"
			;;
	esac
done
