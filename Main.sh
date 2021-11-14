#!/bin/bash

find_all_gpu_costs() 
{

# preparing

	gpu=$1
	temp=$2
	string=`echo $gpu| tr -s "_" "+"`

	if [[ ${gpu: -1} == '+' ]]; then
		string=`echo $string| sed 's/.$//'`
	fi
	
	site=`echo 'https://www.ebay.com/sch/i.html?_from=R40&_trksid=p2334524.m570.l1313&_nkw='$string'+-parts+-non+-not+-box+-chip&_sacat=0&LH_TitleDesc=1&_ftrt=901&_ipg=25&LH_ItemCondition=1000%7C1500%7C2000%7C2500%7C3000&_dmd=1&_stpos=24201&LH_BIN=1&_odkw=+-parts+-non+-not+-box+-chip&_osacat=0&_sop=12&_ftrv=1&_sadis=15'`

# site things
	
	# this is due to some odd erros when using variables whose root causes illuded base debugging. Fix this.
	curl -s $site|tr -s "<>" "\n"|grep 'span class=s-item__price' -A 1| grep -v 'span' | tr -d '$,-' | grep '.' | cut -d '.' -f '1' > $gpu-costs.txt

	# Finding average cost
	avCost=0
	gpuAmt=0
	for cost in `cat "$gpu-costs.txt"`; do
		# try to incorperate ASCII module thing instead of this & put in prev curl line thing ( not on linux rn )
		cost=`echo $cost| tr -d 'qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM"='`
		if [[ "$gpuAmt" == "0" ]]; then		
			costBotThreshold=$(( $cost / 3 ))
		fi
		if [[ "$cost" -gt "$costBotThreshold" ]]; then
			if [[ "$(( $costBotThreshold * 6 ))" -gt "$cost" ]]; then
				avCost=$(( ( $avCost * $gpuAmt + $cost ) / ( $gpuAmt + 1 ) ))
			fi
		fi
		gpuAmt=$(( $gpuAmt + 1 ))
	done


	# calculations and stuff 		
	
	# getting corresponding profits
	locprof=`echo $prof| cut -d " " -f $temp` 

	echo "$prof| cut -d \" \" -f $temp"

	# cutting off leading 0s to prevent error (I.E. 5 / 02.78 )
	while [[ "${locprof:0:1}" == "0" ]]; do
		locprof=${locprof:1}
	done
	
	# finding good deals
	good_deals=""
	gpuAmt=0
	for cost in `cat "$gpu-costs.txt"`; do
		cost=`echo $cost| tr -d 'qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM"='`
		if [[ "$gpuAmt" == "0" ]]; then
			costBotThreshold=$(( $cost / 3 ))
		fi
		if [[ "$cost" -gt "$costBotThreshold" ]]; then
			if [[ $(( avCost * 9 / 10 )) -gt $cost ]]; then
				good_deals+="\$$cost:$(( $cost * 100 / $locprof ))d, "
			fi
		fi
		gpuAmt=$(( $gpuAmt + 1 ))
	done
	
	#rm "$gpu-costs.txt"

	roi=$(( ( $avCost * 100 ) / $locprof ))
	
	
	echo "  
/- $gpu :
| link			 `echo $site|tr -d '"'`
| average cost		 \$$avCost
| average $/day		 \$$(( locprof / 100 )).$(( locprof % 100 )) 
| average ROI		 ~$roi days
| good/fake deals	 $good_deals
" >> Best_GPUs.txt

}

gpu_ordered()
{
	
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
			find_all_gpu_costs $gpu $temp &
		done

		wait
		
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
			find_all_gpu_costs $gpu $temp $prof &
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
			echo "starting ordered GPU finder"; gpu_ordered
			;;
		\?)
			echo -e "-o	GPU cards orded by ROI\n-u	GPU cards unordered"
			;;
	esac
done
