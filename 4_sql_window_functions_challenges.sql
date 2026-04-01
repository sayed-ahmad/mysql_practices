USE atlas;

-- 1. Rank museums by the number of paitings they have.


-- 2. Select only the top 10 ranked museums from the previous question.


-- 3. Rank artists in each style based on the total number of paintings made.


/* 4. Do the styles museums collect vary by country? What are the top 3 styles for each country?
Ignore countries with fewer than three paintings. */

    
-- 5. We know already on which days the most museums are open. What about the SECOND most?


-- 6. How many years between the birth of one artist and another?

    
/* 7. Arrange canvas sizes by total area. Ignore canvases with only one measurement. 
If two canvases have the same area, display the one with the lower width first.
How much bigger (in area) is each canvas size than the previous? */

    
-- 8. How do the number of paintings created vary century-to-century? Use the artist's death to determine the century.


-- 9. Display the above as a percentage change.


-- 10. Categorise the century-by-century variation by whether it was an increase or decrease compared to the previous century.


-- 11. How many centuries in the data showed an increase in paintings created compared to the previous century?


-- 12. Display the above as a percentage of all centuries except the first in the dataset.


/****** BONUS
Find the artists in the top 1% of works created in a lifetime. 
It may help to find an appropriate window function for this task https://dev.mysql.com/doc/refman/8.4/en/window-function-descriptions.html
******/


/****** BONUS 2
If an employee works open to close every day of the week (starting Monday), 
what day do they need to work until to get a 40-hour week? How many days do they work?
Currently, museum hours are sorted with Sunday first. You can use the custom function 
dayname_to_integer() to help sort the days Monday-Sunday. e.g. dayname_to_integer('Monday') = 1, dayname_to_integer('Tuesday') = 2, etc.
More about custom functions tomorrow!
******/
