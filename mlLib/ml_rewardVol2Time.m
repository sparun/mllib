function rewardDurationPerClick = ml_rewardVol2Time(rewardMlPerClick)
         
rewardDurationPerClick = 1000*(1.02 * rewardMlPerClick - 0.0439);

end