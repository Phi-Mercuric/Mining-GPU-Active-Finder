#!/bin/bash

# note: lots of things were probably unnecessarily added because it was assumed that it would help with stability and bugs

gpus=" "
prof=" "
output=""

find_all_gpu_costs() 
{

	gpu=$1
	string=`echo $gpu| tr -s "_" "+"`

	if [[ ${gpu: -1} == '+' ]]; then
	       string=`echo $string| sed 's/.$//'`
	fi
	
	site=`echo 'https://www.ebay.com/sch/i.html?_from=R40&_nkw='$string'+-fits+-for+-cover&_in_kw=1&_ex_kw=&_sacat=0&_udlo=&_udhi=&LH_BIN=1&_ftrt=901&_ftrv=1&_sabdlo=&_sabdhi=&_samilow=&_samihi=&_sadis=15&_stpos=24201&_sargn=-1%26saslc%3D1&_salic=1&_sop=12&_dmd=1&_ipg=200&_fosrp=1'`	

	avCost=0
	
	gpuAmt=0
	

	for cost in `curl -s $site| grep -A 1 '<span  class="bold">'| grep '/span'| tr -d '</span>        $'| cut -d "." -f 1| tr -d ","`; do 
		cost=`echo $cost| tr -d 'qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM"='`
		if [[ "$gpuAmt" == "0" ]]; then
			costBotThreshold=$(( $cost / 3 ))
		fi
		if [[ "$cost" -gt "$costBotThreshold" ]]; then
			avCost=$(( ( $avCost * $gpuAmt + $cost ) / ( $gpuAmt + 1 ) ))
		fi
		gpuAmt=$(( $gpuAmt + 1 ))
	done
		
	locprof=`echo $prof| cut -d " " -f $temp`
	roi=$(( ( $avCost * 100 ) / $locprof ))


	echo "  
/- $gpu :
| link          	 $site
| average cost 		 \$$avCost
| average $/day		 \$$(( locprof / 100 )).$(( locprof % 100 )) 
| average ROI		 ~$roi days 
" >> Best_GPUs.txt

}

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

echo Best_GPUs.txt

rm Best_GPUs.txt

}


main
