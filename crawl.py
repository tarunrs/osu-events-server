import urllib2
import re
import time
from datetime import date, timedelta, datetime
from BeautifulSoup import BeautifulSoup, NavigableString, Tag
from Events import OSUEvents, Categories, Locations, Event_Types
from sqlalchemy.orm import sessionmaker
from sqlalchemy import *

def strip_for_dict(str):
    pattern = re.compile('[\W_]+')
    return pattern.sub('', str)

def load_categories(session):
    dict_c = {}
    db_categories = session.query(Categories)
    for c in db_categories:
        dict_c[strip_for_dict(c.category_title)] = c.category_id    
    return dict_c

def load_event_types(session):
    dict_et = {}
    db_event_types = session.query(Event_Types)
    for c in db_event_types:
        dict_et[strip_for_dict(c.event_type_title)] = c.event_type_id    
    return dict_et    

def load_locations(session):
    dict_l = {}
    db_locations = session.query(Locations)
    for l in db_locations:
        dict_l[strip_for_dict(l.location_title)] = l.location_id    
    return dict_l

def get_osu_events(num_days, session, categories, locations, event_types):
    which_date = date.today()
    td = timedelta(days=1)
    for i in range(num_days):
        str_date = which_date.strftime('%Y-%m-%-d')
        page_url = 'http://www.osu.edu/events/indexDay.php?Event_ID=&Date=' + str_date
        html_doc = urllib2.urlopen(page_url).read()
        soup = BeautifulSoup(html_doc)
        events = soup.table.contents[3].td.findAll("p")
        for e in events:
            event_name = e.contents[0].text    
            event_link = "http://www.osu.edu/events/" + str(e.contents[0]['href'])
            print event_link
            event = OSUEvents(event_name, event_link)
            event.load_details(session, categories, locations, event_types)
            db_event = session.query(OSUEvents).filter_by(event_link=event.event_link).first() 
            if not db_event :
                session.add(event)
                session.commit()
        which_date = which_date + td

db = create_engine('mysql://root:tarun123@localhost/osu_events') 
Session = sessionmaker(bind=db)
db.echo = False
metadata = MetaData()
metadata.create_all(db)
session = Session()
d_locations = load_locations(session)
d_categories = load_categories(session)
d_event_types = load_event_types(session)

print d_locations
print d_categories
print d_event_types
get_osu_events(12, session, d_categories, d_locations, d_event_types)
print d_categories
