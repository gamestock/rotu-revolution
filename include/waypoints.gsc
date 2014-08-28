//
// ########   #######  ######## ##     ##         ########  ######## ##     ##  #######  ##       ##     ## ######## ####  #######  ##    ## 
// ##     ## ##     ##    ##    ##     ##         ##     ## ##       ##     ## ##     ## ##       ##     ##    ##     ##  ##     ## ###   ## 
// ##     ## ##     ##    ##    ##     ##         ##     ## ##       ##     ## ##     ## ##       ##     ##    ##     ##  ##     ## ####  ## 
// ########  ##     ##    ##    ##     ## ####### ########  ######   ##     ## ##     ## ##       ##     ##    ##     ##  ##     ## ## ## ## 
// ##   ##   ##     ##    ##    ##     ##         ##   ##   ##        ##   ##  ##     ## ##       ##     ##    ##     ##  ##     ## ##  #### 
// ##    ##  ##     ##    ##    ##     ##         ##    ##  ##         ## ##   ##     ## ##       ##     ##    ##     ##  ##     ## ##   ### 
// ##     ##  #######     ##     #######          ##     ## ########    ###     #######  ########  #######     ##    ####  #######  ##    ## 
//
// Reign of the Undead - Revolution ALPHA 0.6 by Luk 
// Code contains parts made by Luk, Bipo, Etheross, Brax, Viking, Rycoon and Activision (no shit)
// (Please keep in mind that I'm not the best coder and some stuff might be really dirty)
// If you consider yourself more skilled at coding and would enjoy further developing this, contact me and we could improve this mod even further! (Xfire: lukluk1992 or at http://puffyforum.com)
//
// You may modify this code to your liking (since I - Luk - learned scripting the same way)
// You may also reuse code you find here, as long as you give credit to those who wrote it (5 lines above)
//
// Based on Reign of the Undead 2.1 created by Bipo and Etheross
//

// WAYPOINTS AND PATHFINDING
#include scripts\include\data;

float(number){
	return atof(number);
}

loadWaypoints()
{
	level.Wp = [];
	level.WpCount = 0;
	level.waypointLoops = 0;
	
	fileName =  "waypoints/"+ toLower(getDvar("mapname")) + "_wp.csv";
/#	printLn( "Getting waypoints from csv: "+fileName );		#/

	level.WpCount = int( tableLookup(fileName, 0, 0, 1) );
	for( i=0; i<level.WpCount; i++ )
	{
		waypoint = spawnStruct();
		origin = TableLookup(fileName, 0, i+1, 1);
		orgToks = strtok( origin, " " );
		waypoint.origin = ( float(orgToks[0]), float(orgToks[1]), float(orgToks[2]));
		
		level.Wp[i] = waypoint;
	}

	for( i=0; i<level.WpCount; i++ )
	{
		waypoint = level.Wp[i]; 
		
		strLnk = TableLookup(fileName, 0, i+1, 2);
		tokens = strtok(strLnk, " ");
		
		waypoint.childCount = tokens.size;
		
		for( j=0; j<tokens.size; j++ )
			waypoint.children[j] = int(tokens[j]);
	}
	//thread draw_wp();
}

draw_wp()
{
	while(1)
	{
		for( i=0; i<level.WpCount; i++ )
		{
			for( j=0; j<level.Wp[i].childCount; j++ )
				line( level.Wp[i].origin, level.Wp[level.Wp[i].children[j]].origin);
		}
		wait 0.05;
	}
}

getNearestWp( origin )
{
  nearestWp = -1;
  nearestDistance = 9999999999;
  for(i = 0; i < level.WpCount; i++)
  {
    distance = distancesquared(origin, level.Wp[i].origin);
    
    if(distance < nearestDistance)
    {
      nearestDistance = distance;
      nearestWp = i;
    }
  }
  
  return nearestWp;
}

// ASTAR PATHFINDING ALGORITHM: CREDITS GO TO PEZBOTS!

AStarSearch( startWp, goalWp )
{
	pQOpen = [];
	pQSize = 0;
	closedList = [];
	listSize = 0;
	s = spawnStruct();
	s.g = 0; //start node
	s.h = distance( level.wp[startWp].origin, level.wp[goalWp].origin );
	s.f = s.g + s.h;
	s.wpIdx = startWp;
	s.parent = spawnStruct();
	s.parent.wpIdx = -1;
  
	//push s on Open
	pQOpen[pQSize] = spawnStruct();
	pQOpen[pQSize] = s; //push s on Open
	pQSize++;

	//while Open is not empty  
	while( !PQIsEmpty(pQOpen, pQSize) )
	{
		//pop node n from Open  // n has the lowest f
		n = pQOpen[0];
		highestPriority = 9999999999;
		bestNode = -1;
		for( i=0; i<pQSize; i++ )
		{
			if( pQOpen[i].f < highestPriority )
			{
				bestNode = i;
				highestPriority = pQOpen[i].f;
			}
		} 
    
		if( bestNode != -1 )
		{
			n = pQOpen[bestNode];
			//remove node from queue    
			for( i=bestNode; i<pQSize-1; i++ )
			{
				pQOpen[i] = pQOpen[i+1];
			}
			pQSize--;
		}
		else
		{
			return -1;
		}
    
		//if n is a goal node; construct path, return success
		if( n.wpIdx == goalWp )
		{
			x = n;
			for( z=0; z<1000; z++ )
			{
				parent = x.parent;
				if( parent.parent.wpIdx == -1 )
					return x.wpIdx;
				// line(level.wp[x.wpIdx].origin, level.wp[parent.wpIdx].origin, (0,1,0));
				x = parent;
			}

			return -1;      
		}

		//for each successor nc of n
		for( i=0; i<level.wp[n.wpIdx].childCount; i++ )
		{
			//newg = n.g + cost(n,nc)
			newg = n.g + distance( level.wp[n.wpIdx].origin, level.wp[level.wp[n.wpIdx].children[i]].origin );
      
			//if nc is in Open or Closed, and nc.g <= newg then skip
			if( PQExists(pQOpen, level.wp[n.wpIdx].children[i], pQSize) )
			{
				//find nc in open
				nc = spawnStruct();
				for( p=0; p<pQSize; p++ )
				{
					if( pQOpen[p].wpIdx == level.wp[n.wpIdx].children[i] )
					{
						nc = pQOpen[p];
						break;
					}
				}
				
				if( nc.g <= newg )
				{
					continue;
				}
			}
			else if( PQExists(closedList, level.wp[n.wpIdx].children[i], listSize) )
			{
				//find nc in closed list
				nc = spawnStruct();
				for( p=0; p<listSize; p++ )
				{
					if( closedList[p].wpIdx == level.wp[n.wpIdx].children[i] )
					{
						nc = closedList[p];
						break;
					}
				}
				
				if( nc.g <= newg )
				{
					continue;
				}
			}
			
			nc = spawnStruct();
			nc.parent = n;
			nc.g = newg;
			nc.h = distance( level.wp[level.wp[n.wpIdx].children[i]].origin, level.wp[goalWp].origin );
			nc.f = nc.g + nc.h;
			nc.wpIdx = level.wp[n.wpIdx].children[i];
			
			//if nc is in Closed,
			if( PQExists(closedList, nc.wpIdx, listSize) )
			{
				//remove it from Closed
				deleted = false;
				for( p=0; p<listSize; p++ )
				{
					if( closedList[p].wpIdx == nc.wpIdx )
					{
						for( x=p; x<listSize-1; x++ )
							closedList[x] = closedList[x+1];
						
						deleted = true;
						break;
					}
					
					if( deleted )
						break;
				}
				listSize--;
			}
			
			//if nc is not yet in Open, 
			if( !PQExists(pQOpen, nc.wpIdx, pQSize) )
			{
				//push nc on Open
				pQOpen[pQSize] = nc;
				pQSize++;
			}
		}
		
		//Done with children, push n onto Closed
		if( !PQExists(closedList, n.wpIdx, listSize) )
		{
			closedList[listSize] = n;
			listSize++;
		}
	}
}



////////////////////////////////////////////////////////////
// PQIsEmpty, returns true if empty
////////////////////////////////////////////////////////////
PQIsEmpty(Q, QSize)
{
	if( QSize <= 0 )
	{
		return true;
	}

	return false;
}


////////////////////////////////////////////////////////////
// returns true if n exists in the pQ
////////////////////////////////////////////////////////////
PQExists( Q, n, QSize )
{
	for( i=0; i<QSize; i++ )
	{
		if( Q[i].wpIdx == n )
			return true;
	}

	return false;
}

// DEBUG AND TOOLS


drawWP()
{
	for (;;)
	{
		for (i=0; i<level.WpCount; i++)
		{
			wp = level.Wp[i];
			lineCol = (0,1,0);
			line(wp.origin, wp.origin + (0,0,96), lineCol);
			lineCol = (0,0,1);
			for(ii=0; ii<wp.childCount; ii++)
				line(wp.origin, level.wp[wp.child[ii]].origin, lineCol);
		}

		wait .01;
	}
}

