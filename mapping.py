
from pysqlite2 import dbapi2 as sql
import sys, csv, os, re, subprocess
from sklearn.neighbors import NearestNeighbors
import fiona, glob, multiprocessing
import geopandas as gpd
import numpy as np
import pandas as pd
import datetime
import os, subprocess, shutil, multiprocessing, re, glob


db1 =  "'/Volumes/GoogleDrive/My Drive/disc_data/disc.sqlite'"
db =  "/Volumes/GoogleDrive/My Drive/disc_data/disc.sqlite"
shp = "'/Volumes/GoogleDrive/My Drive/disc_data/raw/spatial/tl_2010_us_county10/tl_2010_us_county10.shp'"
stations = "/Volumes/GoogleDrive/My Drive/disc_data/raw/spatial/ghcnd-stations.txt"
#print os.listdir(location)


# http://spatialreference.org/ref/esri/102003/

def gen_database(db,shp):
	cmd = ['ogr2ogr -f "SQLite" -dsco SPATIALITE=YES -t_srs  ','http://spatialreference.org/ref/epsg/4326/ ',
	               db1,' ',shp,' -nlt PROMOTE_TO_MULTI ']
	subprocess.call(' '.join(cmd),shell=True)
#gen_database(db,shp)



# dofile = "subcode/import_station_table.do"
# cmd = ['stata-mp', 'do', dofile]
# subprocess.call(cmd)



def station_shape(db):    
	con = sql.connect(db)
	cur = con.cursor()
	con.enable_load_extension(True)
	con.execute("SELECT load_extension('mod_spatialite');")

	name='stations_geo'

	def drop_full_table(name):
		chec_qry = '''
                   SELECT type,name from SQLite_Master
                   WHERE type="table" AND name ="{}";
                   '''.format(name)
		drop_qry = '''
                   SELECT DisableSpatialIndex('{}','GEOMETRY');
                   SELECT DiscardGeometryColumn('{}','GEOMETRY');
                   DROP TABLE IF EXISTS idx_{}_GEOMETRY;
                   DROP TABLE IF EXISTS {};
                   '''.format(name,name,name,name)
		cur.execute(chec_qry)
		result = cur.fetchall()
		if result:
			cur.executescript(drop_qry)

	drop_full_table(name)

	qry = '''
            CREATE TABLE {} AS
            SELECT A.ID, A.LATITUDE, A.LONGITUDE, A.STATE, A.OGC_FID, makepoint(A.LONGITUDE,A.LATITUDE,4326) AS GEOMETRY 
            FROM stations AS A
            '''.format(name)
    
	con.execute(qry)
	cur.execute("Select RecoverGeometryColumn ('{}', 'GEOMETRY', 4326, 'POINT', 2);".format(name))
	cur.execute("SELECT CreateSpatialIndex('{}','GEOMETRY');".format(name))
	cur.execute("CREATE INDEX {}_index ON {} ({});".format(name,name,'OGC_FID'))

# station_shape(db)


def station_intersect(db):
	con = sql.connect(db)
	cur = con.cursor()
	con.enable_load_extension(True)
	con.execute("SELECT load_extension('mod_spatialite');")

	name = 'int_stations_county'

	cur.execute("DROP TABLE IF EXISTS {} ; ".format(name))

	qry = '''
            CREATE TABLE {} AS
            SELECT A.geoid10, G.ID
            FROM tl_2010_us_county10 AS A, stations_geo AS G
            WHERE G.ROWID IN (SELECT ROWID FROM SpatialIndex 
                                            WHERE f_table_name='stations_geo' AND search_frame=A.GEOMETRY)
                                            AND st_within(G.GEOMETRY,A.GEOMETRY) 
            GROUP BY G.ID
            '''.format(name)
    
	con.execute(qry)
	cur.execute("CREATE INDEX {}_index ON {} ({});".format(name,name,'geoid10'))
	cur.execute("CREATE INDEX {}_index1 ON {} ({});".format(name,name,'ID'))


#station_intersect(db)




def dist(db,n_count):

	print '\n', " start dist calc ... ", '\n'

	#n_count = 5
	hull= 'county'
	outcome='station'

	con = sql.connect(db)
	con.enable_load_extension(True)
	con.execute("SELECT load_extension('mod_spatialite');")
	cur = con.cursor()

	# 1. import county coordinates
	cur.execute('SELECT ST_x(ST_centroid(GEOMETRY)), ST_y(ST_centroid(GEOMETRY)), OGC_FID FROM tl_2010_us_county10 ')
	in_mat = np.array(cur.fetchall())

	# 2. import station coordinates
	cur.execute('SELECT A.LONGITUDE, A.LATITUDE, A.OGC_FID FROM stations AS A JOIN stations_80 AS B ON A.ID = B.ID')
	targ_mat = np.array(cur.fetchall())

	# compute distance function
	def dist_calc(I_mat,T_mat):
		nbrs = NearestNeighbors(n_neighbors=n_count, algorithm='auto').fit(T_mat)
		dist, ind = nbrs.kneighbors(I_mat)
		return [dist,ind]

	res=dist_calc(in_mat[:,:2],targ_mat[:,:2])

	cur.execute('DROP TABLE IF EXISTS distance_{}_{}_{};'.format(outcome,hull,n_count))
	cur.execute(''' CREATE TABLE distance_{}_{}_{} (
	                input_id     INTEGER,
	                target_id    INTEGER, 
	                distance     numeric(10,10) );'''.format(outcome,hull,n_count))

	rowsqry = '''INSERT INTO distance_{}_{}_{} VALUES (?,?,?);'''.format(outcome,hull,n_count)

	for i in range(0,len(in_mat)):
		for j in range(0,n_count):
			cur.execute(rowsqry, [in_mat[i][2],targ_mat[res[1][i][j]][2],res[0][i][j]])
	
	cur.execute('''CREATE INDEX distance_{}_{}_{}_input_id_ind ON distance_{}_{}_{} (input_id);'''.format(outcome,hull,n_count,outcome,hull,n_count))
	cur.execute('''CREATE INDEX distance_{}_{}_{}_target_id_ind ON distance_{}_{}_{} (target_id);'''.format(outcome,hull,n_count,outcome,hull,n_count))

	con.commit()
	con.close()

	print '\n', " Done :) ... ", '\n'


dist(db,1)
dist(db,5)

