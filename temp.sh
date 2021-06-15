#!/bin/bash

# site things


string='gtx+1080+8gb'

site=`echo 'https://www.ebay.com/sch/i.html?_from=R40&_trksid=p2334524.m570.l1313&_nkw='$string'+-parts+-non+-not+-box+-chip&_sacat=0&LH_TitleDesc=1&_ftrt=901&_ipg=25&LH_ItemCondition=1000%7C1500%7C2000%7C2500%7C3000&_dmd=1&_stpos=24201&LH_BIN=1&_odkw=+-parts+-non+-not+-box+-chip&_osacat=0&_sop=12&_ftrv=1&_sadis=15'`

echo $site

# site things

        # this is due to some odd erros when using variables whose root causes illuded base debugging. Fix this.
        curl $site


# this is due to some odd erros when using variables whose root causes illuded b
