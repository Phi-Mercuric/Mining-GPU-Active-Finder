#!/bin/bash

find_all_gpu_costs() 
{

# preparing

	gpu=$1
	string=`echo $gpu| tr -s "_" "+"`

	if [[ ${gpu: -1} == '+' ]]; then
		string=`echo $string| sed 's/.$//'`
	fi
	
	site=`echo 'https://www.ebay.com/dsc/i.html?_from=R40&_sacat=0&LH_TitleDesc=1&_udlo=&_udhi=&LH_BIN=1&LH_ItemCondition=4&_ftrt=901&_ftrv=1&_sabdlo=&_sabdhi=&_samilow=&_samihi=&_sadis=15&_stpos=24201&_sop=12&_dmd=1&_ipg=25&_fosrp=1&_nkw="'$string'"&_ex_kw=parts+non+not&_in_kw=1'`
	
# site things
	
	# this is due to some odd erros when using variables whose root causes illuded base debugging. Fix this.
	echo `curl -s $site| grep -A 1 '<span  class="bold">'| grep '/span'| tr -d '</span>		$'| cut -d "." -f 1| tr -d ","` >> "$gpu-costs.txt"

	# Finding average cost
	declare -i avCost
	declare -i gpuAmt
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
	
	rm -r "$gpu-costs.txt"

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
		
		prof=`curl -s 'https://whattomine.com/gpus'| grep -A 1 '<td class="text-right table-success font-weight-bold">'| grep -v '<'| grep -v '-'| tr -d '.$'`
		
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
	
	gpus=" "
	prof=" "
	output=""
	
	main () 
	{
		
		echo "Starting..."
		
		echo " " > Best_GPUs.txt
		
		gpus=`curl -s 'https://whattomine.com/gpus'| grep -A 1 -B 1 '</td>'| grep -B 2 '<td class="text-center">'| grep '</a>'| sed 's/<\/a>//'| tr -d '(*)'| sed 's/Unrestricted//'| tr -s " " "_"`
		
		prof=`curl -s 'https://whattomine.com/gpus'| grep -A 1 '<td class="text-right table-success font-weight-bold">'| grep -v '<'| grep -v '-'| tr -d '.$'`
		
		echo ". . ."
		
		temp=0
		
		for gpu in $gpus; do
			temp=$(( $temp + 1 ))
			find_all_gpu_costs $gpu $temp &
		done
		
		wait
		
		cat Best_GPUs.txt
		
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
	
	file=`date +"%d-%m-%y-%T"| cut --complement -d ":" -f 3`
	
	
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
