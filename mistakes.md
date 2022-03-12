---
title: "Predicting Barrels From Pitch Characteristics to Examine Pitcher Mistakes"
author: "Justin Ford"
date: "2/8/2022"
output: 
  html_document:
    keep_md: TRUE
---



## What makes a mistake?

You know it when you see it: the batter's eyes light up, the pitcher's gaze drops to the ground just as the bat connects. A meatball. Even casual baseball fans probably have some familiarity with the concept of a so-called "mistake pitch." The breaking ball that doesn't *quite* break enough, the fastball right down Broadway. Ultimately, I think the simplest definition of a mistake pitch is a pitch that's not just likely to get hit, but likely to get *crushed.* Of course, not every pitch that gets crushed should be classified as a "mistake," nor is every inaccuracy properly punished by the hitter. Sometimes, a batter puts a good swing on a good pitch. Then how can we discern if a pitch is likely to get crushed or not? What makes a pitch a mistake pitch?

The first step is to find out what exactly "crushed" means. There are a few ways to do this: 

*   Set a threshold for run value, so that all batted balls over the threshold are considered crushed. However, run values don't always correlate closely with how "well-hit" a batted ball is. Bloopers tend to have a high run value because they fall for hits often, but wouldn't be considered to be hit squarely or hard. 
*   Use Statcast's Barrel classification as a proxy for "crushed." This is the simplest and most direct option, because these are literally the batted balls that Statcast defines as "hit well." The one issue with using barrels is that batters will have widely differing abilities to hit barrels. Some hitters, like David Fletcher or Myles Straw, will rarely ever have a batted ball classified as a "Barrel," even if they hit it as well as they can. Does that mean it's impossible to throw a mistake pitch to David Fletcher? I don't think so. 
*   Use a subset of the "best" batted balls by each hitter. This solves the problem with using Statcast Barrels. However, I would need to devise a system to come up with evaluating with batted balls are the "best," or rather, "most crushed." The best way I could think to evaluate batted balls is by using run values or the built-in "estimated_woba_using_speedangle" column of the Statcast csv. Of course, this then presents us with the same problem we saw in option 1; estimated_woba_using_speedangle isn't necessarily a measure of how well a ball is hit in the same way that Barrels are.

For simplicity's sake, I decided to just use Barrels as my stand-in for "crushed." It is the most direct measure of what I mean by "crushed" that I have readily available.



So, looking at every pitch from the 2021 season (data retrieved using the excellent baseballr package for scraping from Baseball Savant), I constructed a model that would predict the probability that a given pitch would be barreled. 



The features of my model included pitch velocity, location, movement, pitcher release point and the count. My model does not include any information regarding batter tendencies, or any contextual information about the pitcher's arsenal. It is simply looking on a pitch-by-pitch basis, regardless of batter, and trying to determine how often that pitch gets barreled on average.






After training the model, we can look at what features of the data contribute the most to correctly predicting whether the pitch was barreled or not.

![](mistakes_files/figure-html/importance-1.png)<!-- -->

A more complete description of what some of these attributes are measuring can be found [here](https://baseballsavant.mlb.com/csv-docs), but essentially plate_z and plate_x refer to vertical and horizontal location respectively. These are by far the most important features for them model. This is probably as expected, though I would've expected movement (pfx_x and pfx_z are the measurements for movement) to be a bigger contributor.



We can bin pitches by their location and look at the average barrel probability for pitches in each bin.

![](mistakes_files/figure-html/xbarrel_plot-1.png)<!-- -->
\
As we would expect, pitches nearest the middle of the zone have the highest probability of getting barreled according to the model.
\

## Pitcher Mistakes

Since we have the probability that every pitch will be barreled, we can plot the pitches with the highest barrel probability (these are our "mistakes"). I'm taking the top 1.5% of pitches to be our "mistakes," since this is roughly the percentage of pitches that are barreled league-wide.

![](mistakes_files/figure-html/mistake_plot-1.png)<!-- -->


\
Once again, we see how many mistakes are pitches that are left over the middle of the plate, for all pitch types. We can also see how more mistakes tend to be made on the inside part of the plate. Also, breaking balls and offspeed pitches up in the zone don't really show up here as "mistakes," as maybe conventional wisdom would suggest. 
\

## Which Pitchers Avoid Mistakes?

Now that we have a way to quantify how much of a mistake a pitch is (barrel probability, which I will also call xBarrels), we can look at the pitchers who are the best and worst at avoiding these pitches. However, I don't just want to look at who throws the most mistake pitches, I want to see which pitchers are able to prevent hard hits while also throwing pitches that get lots of swings and called strikes. A pitcher who throws 55 foot curveballs every pitch technically isn't throwing any mistake pitches by our definition, because those pitchers are essentially impossible to barrel. Those pitches, though, have little chance of accomplishing anything positive for the pitcher's team. So, I trained another model which attempted to predict the likelihood that a pitch would either be: a) swung at, or b) called for a strike. I call this likelihood "xChance" (i.e. the "chance" that the pitch results in a strike or batted ball). This way, I'm rewarding pitchers that are able to throw strikes *and* avoid mistakes. 

So we have a measure for the number of "mistakes" a pitcher made (xBarrels), and a measure for the number of "chances" that a pitcher allows for batters to barrel a pitch. We can simply take the proportion of xChances that end up as xBarrels for each pitcher, and we will have a good measure for determining pitchers that throw highly barrelable pitches:


```{=html}
<div id="lkbivobqsu" style="overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>html {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Helvetica Neue', 'Fira Sans', 'Droid Sans', Arial, sans-serif;
}

#lkbivobqsu .gt_table {
  display: table;
  border-collapse: collapse;
  margin-left: auto;
  margin-right: auto;
  color: #333333;
  font-size: 16px;
  font-weight: normal;
  font-style: normal;
  background-color: #FFFFFF;
  width: 700px;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #A8A8A8;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #A8A8A8;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
}

#lkbivobqsu .gt_heading {
  background-color: #FFFFFF;
  text-align: left;
  border-bottom-color: #FFFFFF;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}

#lkbivobqsu .gt_title {
  color: #333333;
  font-size: 125%;
  font-weight: bold;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}

#lkbivobqsu .gt_subtitle {
  color: #333333;
  font-size: 85%;
  font-weight: initial;
  padding-top: 0;
  padding-bottom: 6px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-color: #FFFFFF;
  border-top-width: 0;
}

#lkbivobqsu .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#lkbivobqsu .gt_col_headings {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}

#lkbivobqsu .gt_col_heading {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 6px;
  padding-left: 5px;
  padding-right: 5px;
  overflow-x: hidden;
}

#lkbivobqsu .gt_column_spanner_outer {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  padding-top: 0;
  padding-bottom: 0;
  padding-left: 4px;
  padding-right: 4px;
}

#lkbivobqsu .gt_column_spanner_outer:first-child {
  padding-left: 0;
}

#lkbivobqsu .gt_column_spanner_outer:last-child {
  padding-right: 0;
}

#lkbivobqsu .gt_column_spanner {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 5px;
  overflow-x: hidden;
  display: inline-block;
  width: 100%;
}

#lkbivobqsu .gt_group_heading {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
}

#lkbivobqsu .gt_empty_group_heading {
  padding: 0.5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: middle;
}

#lkbivobqsu .gt_from_md > :first-child {
  margin-top: 0;
}

#lkbivobqsu .gt_from_md > :last-child {
  margin-bottom: 0;
}

#lkbivobqsu .gt_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  margin: 10px;
  border-top-style: solid;
  border-top-width: 1px;
  border-top-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
  overflow-x: hidden;
}

#lkbivobqsu .gt_stub {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 5px;
  padding-right: 5px;
}

#lkbivobqsu .gt_stub_row_group {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 5px;
  padding-right: 5px;
  vertical-align: top;
}

#lkbivobqsu .gt_row_group_first td {
  border-top-width: 2px;
}

#lkbivobqsu .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#lkbivobqsu .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}

#lkbivobqsu .gt_first_summary_row.thick {
  border-top-width: 2px;
}

#lkbivobqsu .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#lkbivobqsu .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#lkbivobqsu .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}

#lkbivobqsu .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}

#lkbivobqsu .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#lkbivobqsu .gt_footnotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}

#lkbivobqsu .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-left: 4px;
  padding-right: 4px;
  padding-left: 5px;
  padding-right: 5px;
}

#lkbivobqsu .gt_sourcenotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}

#lkbivobqsu .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}

#lkbivobqsu .gt_left {
  text-align: left;
}

#lkbivobqsu .gt_center {
  text-align: center;
}

#lkbivobqsu .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}

#lkbivobqsu .gt_font_normal {
  font-weight: normal;
}

#lkbivobqsu .gt_font_bold {
  font-weight: bold;
}

#lkbivobqsu .gt_font_italic {
  font-style: italic;
}

#lkbivobqsu .gt_super {
  font-size: 65%;
}

#lkbivobqsu .gt_footnote_marks {
  font-style: italic;
  font-weight: normal;
  font-size: 75%;
  vertical-align: 0.4em;
}

#lkbivobqsu .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}

#lkbivobqsu .gt_slash_mark {
  font-size: 0.7em;
  line-height: 0.7em;
  vertical-align: 0.15em;
}

#lkbivobqsu .gt_fraction_numerator {
  font-size: 0.6em;
  line-height: 0.6em;
  vertical-align: 0.45em;
}

#lkbivobqsu .gt_fraction_denominator {
  font-size: 0.6em;
  line-height: 0.6em;
  vertical-align: -0.05em;
}
</style>
<table class="gt_table">
  <thead class="gt_header">
    <tr>
      <th colspan="7" class="gt_heading gt_title gt_font_normal" style>Top 10 Barrel Prone Pitchers, 2021 MLB Season</th>
    </tr>
    <tr>
      <th colspan="7" class="gt_heading gt_subtitle gt_font_normal gt_bottom_border" style>1500 pitch min.</th>
    </tr>
  </thead>
  <thead class="gt_col_headings">
    <tr>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1">Pitcher</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1">Pitches</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1">Chances</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1">Barrels</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1">xBarrels (xB)</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1">xChances (xC)</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1">xB/xC</th>
    </tr>
  </thead>
  <tbody class="gt_table_body">
    <tr><td class="gt_row gt_left">Ross Stripling</td>
<td class="gt_row gt_right">1678</td>
<td class="gt_row gt_right">1065</td>
<td class="gt_row gt_right">33</td>
<td class="gt_row gt_right">33.44</td>
<td class="gt_row gt_right">1,090.85</td>
<td class="gt_row gt_right">0.0307</td></tr>
    <tr><td class="gt_row gt_left gt_striped">Kris Bubic</td>
<td class="gt_row gt_right gt_striped">2198</td>
<td class="gt_row gt_right gt_striped">1364</td>
<td class="gt_row gt_right gt_striped">36</td>
<td class="gt_row gt_right gt_striped">42.35</td>
<td class="gt_row gt_right gt_striped">1,393.34</td>
<td class="gt_row gt_right gt_striped">0.0304</td></tr>
    <tr><td class="gt_row gt_left">Caleb Smith</td>
<td class="gt_row gt_right">2055</td>
<td class="gt_row gt_right">1283</td>
<td class="gt_row gt_right">31</td>
<td class="gt_row gt_right">39.00</td>
<td class="gt_row gt_right">1,291.62</td>
<td class="gt_row gt_right">0.0302</td></tr>
    <tr><td class="gt_row gt_left gt_striped">Marco Gonzales</td>
<td class="gt_row gt_right gt_striped">2319</td>
<td class="gt_row gt_right gt_striped">1497</td>
<td class="gt_row gt_right gt_striped">60</td>
<td class="gt_row gt_right gt_striped">44.64</td>
<td class="gt_row gt_right gt_striped">1,500.81</td>
<td class="gt_row gt_right gt_striped">0.0297</td></tr>
    <tr><td class="gt_row gt_left">Eric Lauer</td>
<td class="gt_row gt_right">1938</td>
<td class="gt_row gt_right">1238</td>
<td class="gt_row gt_right">25</td>
<td class="gt_row gt_right">35.79</td>
<td class="gt_row gt_right">1,247.46</td>
<td class="gt_row gt_right">0.0287</td></tr>
    <tr><td class="gt_row gt_left gt_striped">Kolby Allard</td>
<td class="gt_row gt_right gt_striped">2048</td>
<td class="gt_row gt_right gt_striped">1338</td>
<td class="gt_row gt_right gt_striped">46</td>
<td class="gt_row gt_right gt_striped">38.65</td>
<td class="gt_row gt_right gt_striped">1,348.30</td>
<td class="gt_row gt_right gt_striped">0.0287</td></tr>
    <tr><td class="gt_row gt_left">Keegan Akin</td>
<td class="gt_row gt_right">1762</td>
<td class="gt_row gt_right">1152</td>
<td class="gt_row gt_right">35</td>
<td class="gt_row gt_right">33.22</td>
<td class="gt_row gt_right">1,161.28</td>
<td class="gt_row gt_right">0.0286</td></tr>
    <tr><td class="gt_row gt_left gt_striped">Austin Gomber</td>
<td class="gt_row gt_right gt_striped">1840</td>
<td class="gt_row gt_right gt_striped">1200</td>
<td class="gt_row gt_right gt_striped">34</td>
<td class="gt_row gt_right gt_striped">34.01</td>
<td class="gt_row gt_right gt_striped">1,195.96</td>
<td class="gt_row gt_right gt_striped">0.0284</td></tr>
    <tr><td class="gt_row gt_left">Tyler Anderson</td>
<td class="gt_row gt_right">2573</td>
<td class="gt_row gt_right">1775</td>
<td class="gt_row gt_right">48</td>
<td class="gt_row gt_right">50.07</td>
<td class="gt_row gt_right">1,770.50</td>
<td class="gt_row gt_right">0.0283</td></tr>
    <tr><td class="gt_row gt_left gt_striped">Zach Plesac</td>
<td class="gt_row gt_right gt_striped">2200</td>
<td class="gt_row gt_right gt_striped">1451</td>
<td class="gt_row gt_right gt_striped">48</td>
<td class="gt_row gt_right gt_striped">40.58</td>
<td class="gt_row gt_right gt_striped">1,435.21</td>
<td class="gt_row gt_right gt_striped">0.0283</td></tr>
  </tbody>
  
  
</table>
</div>
```

\
And the pitchers who are the best at throwing hard-to-barrel pitches:

\

```{=html}
<div id="bwwnhrbbyz" style="overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>html {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Helvetica Neue', 'Fira Sans', 'Droid Sans', Arial, sans-serif;
}

#bwwnhrbbyz .gt_table {
  display: table;
  border-collapse: collapse;
  margin-left: auto;
  margin-right: auto;
  color: #333333;
  font-size: 16px;
  font-weight: normal;
  font-style: normal;
  background-color: #FFFFFF;
  width: 700px;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #A8A8A8;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #A8A8A8;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
}

#bwwnhrbbyz .gt_heading {
  background-color: #FFFFFF;
  text-align: left;
  border-bottom-color: #FFFFFF;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}

#bwwnhrbbyz .gt_title {
  color: #333333;
  font-size: 125%;
  font-weight: bold;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}

#bwwnhrbbyz .gt_subtitle {
  color: #333333;
  font-size: 85%;
  font-weight: initial;
  padding-top: 0;
  padding-bottom: 6px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-color: #FFFFFF;
  border-top-width: 0;
}

#bwwnhrbbyz .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#bwwnhrbbyz .gt_col_headings {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}

#bwwnhrbbyz .gt_col_heading {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 6px;
  padding-left: 5px;
  padding-right: 5px;
  overflow-x: hidden;
}

#bwwnhrbbyz .gt_column_spanner_outer {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  padding-top: 0;
  padding-bottom: 0;
  padding-left: 4px;
  padding-right: 4px;
}

#bwwnhrbbyz .gt_column_spanner_outer:first-child {
  padding-left: 0;
}

#bwwnhrbbyz .gt_column_spanner_outer:last-child {
  padding-right: 0;
}

#bwwnhrbbyz .gt_column_spanner {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 5px;
  overflow-x: hidden;
  display: inline-block;
  width: 100%;
}

#bwwnhrbbyz .gt_group_heading {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
}

#bwwnhrbbyz .gt_empty_group_heading {
  padding: 0.5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: middle;
}

#bwwnhrbbyz .gt_from_md > :first-child {
  margin-top: 0;
}

#bwwnhrbbyz .gt_from_md > :last-child {
  margin-bottom: 0;
}

#bwwnhrbbyz .gt_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  margin: 10px;
  border-top-style: solid;
  border-top-width: 1px;
  border-top-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
  overflow-x: hidden;
}

#bwwnhrbbyz .gt_stub {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 5px;
  padding-right: 5px;
}

#bwwnhrbbyz .gt_stub_row_group {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 5px;
  padding-right: 5px;
  vertical-align: top;
}

#bwwnhrbbyz .gt_row_group_first td {
  border-top-width: 2px;
}

#bwwnhrbbyz .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#bwwnhrbbyz .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}

#bwwnhrbbyz .gt_first_summary_row.thick {
  border-top-width: 2px;
}

#bwwnhrbbyz .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#bwwnhrbbyz .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#bwwnhrbbyz .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}

#bwwnhrbbyz .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}

#bwwnhrbbyz .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#bwwnhrbbyz .gt_footnotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}

#bwwnhrbbyz .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-left: 4px;
  padding-right: 4px;
  padding-left: 5px;
  padding-right: 5px;
}

#bwwnhrbbyz .gt_sourcenotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}

#bwwnhrbbyz .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}

#bwwnhrbbyz .gt_left {
  text-align: left;
}

#bwwnhrbbyz .gt_center {
  text-align: center;
}

#bwwnhrbbyz .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}

#bwwnhrbbyz .gt_font_normal {
  font-weight: normal;
}

#bwwnhrbbyz .gt_font_bold {
  font-weight: bold;
}

#bwwnhrbbyz .gt_font_italic {
  font-style: italic;
}

#bwwnhrbbyz .gt_super {
  font-size: 65%;
}

#bwwnhrbbyz .gt_footnote_marks {
  font-style: italic;
  font-weight: normal;
  font-size: 75%;
  vertical-align: 0.4em;
}

#bwwnhrbbyz .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}

#bwwnhrbbyz .gt_slash_mark {
  font-size: 0.7em;
  line-height: 0.7em;
  vertical-align: 0.15em;
}

#bwwnhrbbyz .gt_fraction_numerator {
  font-size: 0.6em;
  line-height: 0.6em;
  vertical-align: 0.45em;
}

#bwwnhrbbyz .gt_fraction_denominator {
  font-size: 0.6em;
  line-height: 0.6em;
  vertical-align: -0.05em;
}
</style>
<table class="gt_table">
  <thead class="gt_header">
    <tr>
      <th colspan="7" class="gt_heading gt_title gt_font_normal" style>Top 10 <em>Least</em> Barrel Prone Pitchers, 2021 MLB Season</th>
    </tr>
    <tr>
      <th colspan="7" class="gt_heading gt_subtitle gt_font_normal gt_bottom_border" style>1500 pitch min.</th>
    </tr>
  </thead>
  <thead class="gt_col_headings">
    <tr>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1">Pitcher</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1">Pitches</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1">Chances</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1">Barrels</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1">xBarrels (xB)</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1">xChances (xC)</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1">xB/xC</th>
    </tr>
  </thead>
  <tbody class="gt_table_body">
    <tr><td class="gt_row gt_left">Luis Castillo</td>
<td class="gt_row gt_right">3139</td>
<td class="gt_row gt_right">1993</td>
<td class="gt_row gt_right">25</td>
<td class="gt_row gt_right">30.75</td>
<td class="gt_row gt_right">1978.7602</td>
<td class="gt_row gt_right">0.0155</td></tr>
    <tr><td class="gt_row gt_left gt_striped">Logan Webb</td>
<td class="gt_row gt_right gt_striped">2205</td>
<td class="gt_row gt_right gt_striped">1432</td>
<td class="gt_row gt_right gt_striped">21</td>
<td class="gt_row gt_right gt_striped">24.33</td>
<td class="gt_row gt_right gt_striped">1428.5178</td>
<td class="gt_row gt_right gt_striped">0.0170</td></tr>
    <tr><td class="gt_row gt_left">Lance McCullers</td>
<td class="gt_row gt_right">2784</td>
<td class="gt_row gt_right">1707</td>
<td class="gt_row gt_right">27</td>
<td class="gt_row gt_right">30.19</td>
<td class="gt_row gt_right">1753.2585</td>
<td class="gt_row gt_right">0.0172</td></tr>
    <tr><td class="gt_row gt_left gt_striped">Gerrit Cole</td>
<td class="gt_row gt_right gt_striped">2966</td>
<td class="gt_row gt_right gt_striped">1972</td>
<td class="gt_row gt_right gt_striped">46</td>
<td class="gt_row gt_right gt_striped">33.44</td>
<td class="gt_row gt_right gt_striped">1925.5431</td>
<td class="gt_row gt_right gt_striped">0.0174</td></tr>
    <tr><td class="gt_row gt_left">Corbin Burnes</td>
<td class="gt_row gt_right">2574</td>
<td class="gt_row gt_right">1702</td>
<td class="gt_row gt_right">18</td>
<td class="gt_row gt_right">29.96</td>
<td class="gt_row gt_right">1619.6559</td>
<td class="gt_row gt_right">0.0185</td></tr>
    <tr><td class="gt_row gt_left gt_striped">Charlie Morton</td>
<td class="gt_row gt_right gt_striped">2967</td>
<td class="gt_row gt_right gt_striped">1911</td>
<td class="gt_row gt_right gt_striped">25</td>
<td class="gt_row gt_right gt_striped">36.00</td>
<td class="gt_row gt_right gt_striped">1940.5631</td>
<td class="gt_row gt_right gt_striped">0.0186</td></tr>
    <tr><td class="gt_row gt_left">Sandy Alcantara</td>
<td class="gt_row gt_right">3077</td>
<td class="gt_row gt_right">2083</td>
<td class="gt_row gt_right">39</td>
<td class="gt_row gt_right">38.84</td>
<td class="gt_row gt_right">2070.2882</td>
<td class="gt_row gt_right">0.0188</td></tr>
    <tr><td class="gt_row gt_left gt_striped">Aaron Nola</td>
<td class="gt_row gt_right gt_striped">2957</td>
<td class="gt_row gt_right gt_striped">1993</td>
<td class="gt_row gt_right gt_striped">38</td>
<td class="gt_row gt_right gt_striped">37.48</td>
<td class="gt_row gt_right gt_striped">1972.5812</td>
<td class="gt_row gt_right gt_striped">0.0190</td></tr>
    <tr><td class="gt_row gt_left">Alex Cobb</td>
<td class="gt_row gt_right">1574</td>
<td class="gt_row gt_right">997</td>
<td class="gt_row gt_right">11</td>
<td class="gt_row gt_right">19.39</td>
<td class="gt_row gt_right">985.5028</td>
<td class="gt_row gt_right">0.0197</td></tr>
    <tr><td class="gt_row gt_left gt_striped">Zack Wheeler</td>
<td class="gt_row gt_right gt_striped">3179</td>
<td class="gt_row gt_right gt_striped">2138</td>
<td class="gt_row gt_right gt_striped">30</td>
<td class="gt_row gt_right gt_striped">42.42</td>
<td class="gt_row gt_right gt_striped">2152.0332</td>
<td class="gt_row gt_right gt_striped">0.0197</td></tr>
  </tbody>
  
  
</table>
</div>
```
\

We can also look at what individual pitches are thrown for "mistakes" the most often.



\


```{=html}
<div id="whsaaoqqww" style="overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>html {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Helvetica Neue', 'Fira Sans', 'Droid Sans', Arial, sans-serif;
}

#whsaaoqqww .gt_table {
  display: table;
  border-collapse: collapse;
  margin-left: auto;
  margin-right: auto;
  color: #333333;
  font-size: 16px;
  font-weight: normal;
  font-style: normal;
  background-color: #FFFFFF;
  width: 700px;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #A8A8A8;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #A8A8A8;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
}

#whsaaoqqww .gt_heading {
  background-color: #FFFFFF;
  text-align: left;
  border-bottom-color: #FFFFFF;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}

#whsaaoqqww .gt_title {
  color: #333333;
  font-size: 125%;
  font-weight: bold;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}

#whsaaoqqww .gt_subtitle {
  color: #333333;
  font-size: 85%;
  font-weight: initial;
  padding-top: 0;
  padding-bottom: 6px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-color: #FFFFFF;
  border-top-width: 0;
}

#whsaaoqqww .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#whsaaoqqww .gt_col_headings {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}

#whsaaoqqww .gt_col_heading {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 6px;
  padding-left: 5px;
  padding-right: 5px;
  overflow-x: hidden;
}

#whsaaoqqww .gt_column_spanner_outer {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  padding-top: 0;
  padding-bottom: 0;
  padding-left: 4px;
  padding-right: 4px;
}

#whsaaoqqww .gt_column_spanner_outer:first-child {
  padding-left: 0;
}

#whsaaoqqww .gt_column_spanner_outer:last-child {
  padding-right: 0;
}

#whsaaoqqww .gt_column_spanner {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 5px;
  overflow-x: hidden;
  display: inline-block;
  width: 100%;
}

#whsaaoqqww .gt_group_heading {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
}

#whsaaoqqww .gt_empty_group_heading {
  padding: 0.5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: middle;
}

#whsaaoqqww .gt_from_md > :first-child {
  margin-top: 0;
}

#whsaaoqqww .gt_from_md > :last-child {
  margin-bottom: 0;
}

#whsaaoqqww .gt_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  margin: 10px;
  border-top-style: solid;
  border-top-width: 1px;
  border-top-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
  overflow-x: hidden;
}

#whsaaoqqww .gt_stub {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 5px;
  padding-right: 5px;
}

#whsaaoqqww .gt_stub_row_group {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 5px;
  padding-right: 5px;
  vertical-align: top;
}

#whsaaoqqww .gt_row_group_first td {
  border-top-width: 2px;
}

#whsaaoqqww .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#whsaaoqqww .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}

#whsaaoqqww .gt_first_summary_row.thick {
  border-top-width: 2px;
}

#whsaaoqqww .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#whsaaoqqww .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#whsaaoqqww .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}

#whsaaoqqww .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}

#whsaaoqqww .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#whsaaoqqww .gt_footnotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}

#whsaaoqqww .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-left: 4px;
  padding-right: 4px;
  padding-left: 5px;
  padding-right: 5px;
}

#whsaaoqqww .gt_sourcenotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}

#whsaaoqqww .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}

#whsaaoqqww .gt_left {
  text-align: left;
}

#whsaaoqqww .gt_center {
  text-align: center;
}

#whsaaoqqww .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}

#whsaaoqqww .gt_font_normal {
  font-weight: normal;
}

#whsaaoqqww .gt_font_bold {
  font-weight: bold;
}

#whsaaoqqww .gt_font_italic {
  font-style: italic;
}

#whsaaoqqww .gt_super {
  font-size: 65%;
}

#whsaaoqqww .gt_footnote_marks {
  font-style: italic;
  font-weight: normal;
  font-size: 75%;
  vertical-align: 0.4em;
}

#whsaaoqqww .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}

#whsaaoqqww .gt_slash_mark {
  font-size: 0.7em;
  line-height: 0.7em;
  vertical-align: 0.15em;
}

#whsaaoqqww .gt_fraction_numerator {
  font-size: 0.6em;
  line-height: 0.6em;
  vertical-align: 0.45em;
}

#whsaaoqqww .gt_fraction_denominator {
  font-size: 0.6em;
  line-height: 0.6em;
  vertical-align: -0.05em;
}
</style>
<table class="gt_table">
  <thead class="gt_header">
    <tr>
      <th colspan="8" class="gt_heading gt_title gt_font_normal" style>Top 10 Mistake Prone Pitches, 2021 MLB Season</th>
    </tr>
    <tr>
      <th colspan="8" class="gt_heading gt_subtitle gt_font_normal gt_bottom_border" style>500 pitch min.</th>
    </tr>
  </thead>
  <thead class="gt_col_headings">
    <tr>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1">Pitcher</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1">Pitch</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1">Pitches</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1">Chances</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1">Barrels</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1">xBarrels (xB)</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1">xChances (xC)</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1">xB/xC</th>
    </tr>
  </thead>
  <tbody class="gt_table_body">
    <tr><td class="gt_row gt_left">Cole Irvin</td>
<td class="gt_row gt_left">4-Seam Fastball</td>
<td class="gt_row gt_right">1086</td>
<td class="gt_row gt_right">759</td>
<td class="gt_row gt_right">19</td>
<td class="gt_row gt_right">26.68</td>
<td class="gt_row gt_right">775.1186</td>
<td class="gt_row gt_right">0.0344</td></tr>
    <tr><td class="gt_row gt_left gt_striped">Austin Gomber</td>
<td class="gt_row gt_left gt_striped">4-Seam Fastball</td>
<td class="gt_row gt_right gt_striped">744</td>
<td class="gt_row gt_right gt_striped">489</td>
<td class="gt_row gt_right gt_striped">20</td>
<td class="gt_row gt_right gt_striped">16.77</td>
<td class="gt_row gt_right gt_striped">492.7852</td>
<td class="gt_row gt_right gt_striped">0.0340</td></tr>
    <tr><td class="gt_row gt_left">Ross Stripling</td>
<td class="gt_row gt_left">4-Seam Fastball</td>
<td class="gt_row gt_right">854</td>
<td class="gt_row gt_right">558</td>
<td class="gt_row gt_right">19</td>
<td class="gt_row gt_right">19.39</td>
<td class="gt_row gt_right">570.3857</td>
<td class="gt_row gt_right">0.0340</td></tr>
    <tr><td class="gt_row gt_left gt_striped">Caleb Smith</td>
<td class="gt_row gt_left gt_striped">4-Seam Fastball</td>
<td class="gt_row gt_right gt_striped">991</td>
<td class="gt_row gt_right gt_striped">607</td>
<td class="gt_row gt_right gt_striped">20</td>
<td class="gt_row gt_right gt_striped">20.73</td>
<td class="gt_row gt_right gt_striped">618.5581</td>
<td class="gt_row gt_right gt_striped">0.0335</td></tr>
    <tr><td class="gt_row gt_left">Michael Pineda</td>
<td class="gt_row gt_left">4-Seam Fastball</td>
<td class="gt_row gt_right">917</td>
<td class="gt_row gt_right">687</td>
<td class="gt_row gt_right">21</td>
<td class="gt_row gt_right">22.42</td>
<td class="gt_row gt_right">675.0106</td>
<td class="gt_row gt_right">0.0332</td></tr>
    <tr><td class="gt_row gt_left gt_striped">Kris Bubic</td>
<td class="gt_row gt_left gt_striped">4-Seam Fastball</td>
<td class="gt_row gt_right gt_striped">1142</td>
<td class="gt_row gt_right gt_striped">704</td>
<td class="gt_row gt_right gt_striped">14</td>
<td class="gt_row gt_right gt_striped">24.08</td>
<td class="gt_row gt_right gt_striped">728.6825</td>
<td class="gt_row gt_right gt_striped">0.0330</td></tr>
    <tr><td class="gt_row gt_left">Lucas Giolito</td>
<td class="gt_row gt_left">Changeup</td>
<td class="gt_row gt_right">938</td>
<td class="gt_row gt_right">666</td>
<td class="gt_row gt_right">8</td>
<td class="gt_row gt_right">21.19</td>
<td class="gt_row gt_right">642.9885</td>
<td class="gt_row gt_right">0.0330</td></tr>
    <tr><td class="gt_row gt_left gt_striped">Rich Hill</td>
<td class="gt_row gt_left gt_striped">4-Seam Fastball</td>
<td class="gt_row gt_right gt_striped">1165</td>
<td class="gt_row gt_right gt_striped">829</td>
<td class="gt_row gt_right gt_striped">19</td>
<td class="gt_row gt_right gt_striped">26.84</td>
<td class="gt_row gt_right gt_striped">815.3575</td>
<td class="gt_row gt_right gt_striped">0.0329</td></tr>
    <tr><td class="gt_row gt_left">J. A. Happ</td>
<td class="gt_row gt_left">4-Seam Fastball</td>
<td class="gt_row gt_right">1437</td>
<td class="gt_row gt_right">945</td>
<td class="gt_row gt_right">31</td>
<td class="gt_row gt_right">29.86</td>
<td class="gt_row gt_right">924.3057</td>
<td class="gt_row gt_right">0.0323</td></tr>
    <tr><td class="gt_row gt_left gt_striped">Dean Kremer</td>
<td class="gt_row gt_left gt_striped">4-Seam Fastball</td>
<td class="gt_row gt_right gt_striped">547</td>
<td class="gt_row gt_right gt_striped">360</td>
<td class="gt_row gt_right gt_striped">13</td>
<td class="gt_row gt_right gt_striped">12.11</td>
<td class="gt_row gt_right gt_striped">378.6366</td>
<td class="gt_row gt_right gt_striped">0.0320</td></tr>
  </tbody>
  
  
</table>
</div>
```

\
An interesting one here is Lucas Giolito's changeup, which was actually a very good pitch for him last season (-11 run value according to Baseball Savant), but is significantly outperforming my xB measure. It's not clear to me whether Giolito simply got lucky with his changeup last year (it also graded out well in 2019 and 2020 my run value so this doesn't appear to be very likely), or if there's some attributes of the pitch that aren't captured by my model. Most of the rest of the pitches in this group are fastballs from pitchers with below average velocity, which is the type of pitch I would expect to see get barrelled often.
\

And finally, the ten pitches least likely to be "mistakes" in 2021.
\

```{=html}
<div id="ekajcpjtfz" style="overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>html {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Helvetica Neue', 'Fira Sans', 'Droid Sans', Arial, sans-serif;
}

#ekajcpjtfz .gt_table {
  display: table;
  border-collapse: collapse;
  margin-left: auto;
  margin-right: auto;
  color: #333333;
  font-size: 16px;
  font-weight: normal;
  font-style: normal;
  background-color: #FFFFFF;
  width: 700px;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #A8A8A8;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #A8A8A8;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
}

#ekajcpjtfz .gt_heading {
  background-color: #FFFFFF;
  text-align: left;
  border-bottom-color: #FFFFFF;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}

#ekajcpjtfz .gt_title {
  color: #333333;
  font-size: 125%;
  font-weight: bold;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}

#ekajcpjtfz .gt_subtitle {
  color: #333333;
  font-size: 85%;
  font-weight: initial;
  padding-top: 0;
  padding-bottom: 6px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-color: #FFFFFF;
  border-top-width: 0;
}

#ekajcpjtfz .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#ekajcpjtfz .gt_col_headings {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}

#ekajcpjtfz .gt_col_heading {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 6px;
  padding-left: 5px;
  padding-right: 5px;
  overflow-x: hidden;
}

#ekajcpjtfz .gt_column_spanner_outer {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  padding-top: 0;
  padding-bottom: 0;
  padding-left: 4px;
  padding-right: 4px;
}

#ekajcpjtfz .gt_column_spanner_outer:first-child {
  padding-left: 0;
}

#ekajcpjtfz .gt_column_spanner_outer:last-child {
  padding-right: 0;
}

#ekajcpjtfz .gt_column_spanner {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 5px;
  overflow-x: hidden;
  display: inline-block;
  width: 100%;
}

#ekajcpjtfz .gt_group_heading {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
}

#ekajcpjtfz .gt_empty_group_heading {
  padding: 0.5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: middle;
}

#ekajcpjtfz .gt_from_md > :first-child {
  margin-top: 0;
}

#ekajcpjtfz .gt_from_md > :last-child {
  margin-bottom: 0;
}

#ekajcpjtfz .gt_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  margin: 10px;
  border-top-style: solid;
  border-top-width: 1px;
  border-top-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
  overflow-x: hidden;
}

#ekajcpjtfz .gt_stub {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 5px;
  padding-right: 5px;
}

#ekajcpjtfz .gt_stub_row_group {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 5px;
  padding-right: 5px;
  vertical-align: top;
}

#ekajcpjtfz .gt_row_group_first td {
  border-top-width: 2px;
}

#ekajcpjtfz .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#ekajcpjtfz .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}

#ekajcpjtfz .gt_first_summary_row.thick {
  border-top-width: 2px;
}

#ekajcpjtfz .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#ekajcpjtfz .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#ekajcpjtfz .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}

#ekajcpjtfz .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}

#ekajcpjtfz .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#ekajcpjtfz .gt_footnotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}

#ekajcpjtfz .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-left: 4px;
  padding-right: 4px;
  padding-left: 5px;
  padding-right: 5px;
}

#ekajcpjtfz .gt_sourcenotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}

#ekajcpjtfz .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}

#ekajcpjtfz .gt_left {
  text-align: left;
}

#ekajcpjtfz .gt_center {
  text-align: center;
}

#ekajcpjtfz .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}

#ekajcpjtfz .gt_font_normal {
  font-weight: normal;
}

#ekajcpjtfz .gt_font_bold {
  font-weight: bold;
}

#ekajcpjtfz .gt_font_italic {
  font-style: italic;
}

#ekajcpjtfz .gt_super {
  font-size: 65%;
}

#ekajcpjtfz .gt_footnote_marks {
  font-style: italic;
  font-weight: normal;
  font-size: 75%;
  vertical-align: 0.4em;
}

#ekajcpjtfz .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}

#ekajcpjtfz .gt_slash_mark {
  font-size: 0.7em;
  line-height: 0.7em;
  vertical-align: 0.15em;
}

#ekajcpjtfz .gt_fraction_numerator {
  font-size: 0.6em;
  line-height: 0.6em;
  vertical-align: 0.45em;
}

#ekajcpjtfz .gt_fraction_denominator {
  font-size: 0.6em;
  line-height: 0.6em;
  vertical-align: -0.05em;
}
</style>
<table class="gt_table">
  <thead class="gt_header">
    <tr>
      <th colspan="8" class="gt_heading gt_title gt_font_normal" style>Top 10 <em>Least</em> Barrel Prone Pitches, 2021 MLB Season</th>
    </tr>
    <tr>
      <th colspan="8" class="gt_heading gt_subtitle gt_font_normal gt_bottom_border" style>500 pitch min.</th>
    </tr>
  </thead>
  <thead class="gt_col_headings">
    <tr>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1">Pitcher</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1">Pitch</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1">Pitches</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1">Chances</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1">Barrels</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1">xBarrels (xB)</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1">xChances (xC)</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1">xB/xC</th>
    </tr>
  </thead>
  <tbody class="gt_table_body">
    <tr><td class="gt_row gt_left">Tyler Rogers</td>
<td class="gt_row gt_left">4-Seam Fastball</td>
<td class="gt_row gt_right">599</td>
<td class="gt_row gt_right">456</td>
<td class="gt_row gt_right">1</td>
<td class="gt_row gt_right">3.87</td>
<td class="gt_row gt_right">451.5998</td>
<td class="gt_row gt_right">0.0086</td></tr>
    <tr><td class="gt_row gt_left gt_striped">Emmanuel Clase</td>
<td class="gt_row gt_left gt_striped">Cutter</td>
<td class="gt_row gt_right gt_striped">731</td>
<td class="gt_row gt_right gt_striped">503</td>
<td class="gt_row gt_right gt_striped">3</td>
<td class="gt_row gt_right gt_striped">6.18</td>
<td class="gt_row gt_right gt_striped">495.6977</td>
<td class="gt_row gt_right gt_striped">0.0125</td></tr>
    <tr><td class="gt_row gt_left">Luis Castillo</td>
<td class="gt_row gt_left">Sinker</td>
<td class="gt_row gt_right">748</td>
<td class="gt_row gt_right">507</td>
<td class="gt_row gt_right">9</td>
<td class="gt_row gt_right">7.03</td>
<td class="gt_row gt_right">517.3606</td>
<td class="gt_row gt_right">0.0136</td></tr>
    <tr><td class="gt_row gt_left gt_striped">Miguel Castro</td>
<td class="gt_row gt_left gt_striped">Sinker</td>
<td class="gt_row gt_right gt_striped">523</td>
<td class="gt_row gt_right gt_striped">297</td>
<td class="gt_row gt_right gt_striped">7</td>
<td class="gt_row gt_right gt_striped">4.15</td>
<td class="gt_row gt_right gt_striped">305.2986</td>
<td class="gt_row gt_right gt_striped">0.0136</td></tr>
    <tr><td class="gt_row gt_left">Sonny Gray</td>
<td class="gt_row gt_left">Curveball</td>
<td class="gt_row gt_right">510</td>
<td class="gt_row gt_right">300</td>
<td class="gt_row gt_right">2</td>
<td class="gt_row gt_right">4.16</td>
<td class="gt_row gt_right">304.1963</td>
<td class="gt_row gt_right">0.0137</td></tr>
    <tr><td class="gt_row gt_left gt_striped">Sandy Alcantara</td>
<td class="gt_row gt_left gt_striped">Sinker</td>
<td class="gt_row gt_right gt_striped">865</td>
<td class="gt_row gt_right gt_striped">615</td>
<td class="gt_row gt_right gt_striped">6</td>
<td class="gt_row gt_right gt_striped">8.48</td>
<td class="gt_row gt_right gt_striped">616.9510</td>
<td class="gt_row gt_right gt_striped">0.0137</td></tr>
    <tr><td class="gt_row gt_left">Logan Webb</td>
<td class="gt_row gt_left">Slider</td>
<td class="gt_row gt_right">611</td>
<td class="gt_row gt_right">386</td>
<td class="gt_row gt_right">5</td>
<td class="gt_row gt_right">5.17</td>
<td class="gt_row gt_right">365.9697</td>
<td class="gt_row gt_right">0.0141</td></tr>
    <tr><td class="gt_row gt_left gt_striped">Luis Castillo</td>
<td class="gt_row gt_left gt_striped">Changeup</td>
<td class="gt_row gt_right gt_striped">959</td>
<td class="gt_row gt_right gt_striped">624</td>
<td class="gt_row gt_right gt_striped">4</td>
<td class="gt_row gt_right gt_striped">8.67</td>
<td class="gt_row gt_right gt_striped">610.4705</td>
<td class="gt_row gt_right gt_striped">0.0142</td></tr>
    <tr><td class="gt_row gt_left">Charlie Morton</td>
<td class="gt_row gt_left">Curveball</td>
<td class="gt_row gt_right">1091</td>
<td class="gt_row gt_right">708</td>
<td class="gt_row gt_right">4</td>
<td class="gt_row gt_right">10.21</td>
<td class="gt_row gt_right">712.6517</td>
<td class="gt_row gt_right">0.0143</td></tr>
    <tr><td class="gt_row gt_left gt_striped">Jeurys Familia</td>
<td class="gt_row gt_left gt_striped">Sinker</td>
<td class="gt_row gt_right gt_striped">594</td>
<td class="gt_row gt_right gt_striped">413</td>
<td class="gt_row gt_right gt_striped">8</td>
<td class="gt_row gt_right gt_striped">5.90</td>
<td class="gt_row gt_right gt_striped">411.1640</td>
<td class="gt_row gt_right gt_striped">0.0143</td></tr>
  </tbody>
  
  
</table>
</div>
```


## Conclusion

Now we have a bit of a better sense of what makes a mistake pitch, even if what we found out mostly aligns with conventional wisdom. Pitches in the heart of the plate are the most likely to get damage inflicted upon them, and hitters tend to barrel more pitches that creep onto the inside half of the plate. Our model also showed that breaking balls and offspeed pitches up in the zone are not as punished as one might think.
