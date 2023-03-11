#!/usr/local/bin/python

"""
@package fisp
@file scrape_ads.py
@author Edward Hunter
@brief Webscrape presidential campain ad trascripts.
"""

import re
import urllib2
import argparse

from bs4 import BeautifulSoup

# Landing page where the campaign and PAC urls are found.
main_url = 'http://www.p2016.org/ads1/paidads.html'
base_url = main_url[: main_url.rfind('/')+1]

# Notes of error conditions in the HTML.
"""
empty links: numerous links with '' or ' ' content (not retrieved).
misspelled: http://www.p2016.org/ads1/clntonad122915r.html (not retrieved).
misspelled: http://www.p2016.org/ads1/sandersad110115.;html (not retrieved).
There are misplaced jindal (1), kaisich (2), and pataki (1) ads following trump (retrieved).
"""

# Test URLS.
test_urls = [
  'http://www.p2016.org/ads1/bushad021016r.html',
  'http://www.p2016.org/ads1/bushad020516.html',
  'http://www.p2016.org/ads1/bushadbackbone.html',
  'http://www.p2016.org/ads1/bushad020216.html',
  'http://www.p2016.org/ads1/bushad012716.html',
  'http://www.p2016.org/ads1/bushad012116r.html',
  'http://www.p2016.org/ads1/bushadenough.html',
  'http://www.p2016.org/ads1/bushad011316.html',
  'http://www.p2016.org/ads1/bushad010416.html',
  'http://www.p2016.org/ads1/bushad120215.html',
  'http://www.p2016.org/ads1/bushad090815.html'
]

# The campaigns.
campaigns = [
  'bush',
  'carson',
  'christie',
  'cruz',
  'fiorina',
  'gilmore',
  'graham',
  'huckabee',
  'kasich',
  'pataki',
  'paul',
  'rubio',
  'santorum',
  'trump',
  'jindal',
  'clinton',
  'sanders',
  'lessig'
]

def scrape(url):
  """
  Parse and extract ad transcript.
  @param url The url of the ad transcript html.
  @retval (org, title, desc, contents) tuple.
  """

  # Make soup.
  print 'Opening URL %s' % str(url)
  f = urllib2.urlopen(url)
  soup = BeautifulSoup(f, 'html.parser')
  
  # Get key tags.
  org = soup.find('div', id='adorg').get_text(strip=True).replace('\n',' ')
  title, desc = soup.find('div', id='adtitle').get_text(strip=True).replace('\n',' ').split('+')
  ov = soup.find('div', id='overview')

  # Navigate and extract content.
  content = []
  for tag in ov.children:
    if tag.name == 'p':
      content.append(tag.get_text(strip=True).replace('\n',' '))
    elif tag.name == 'br':
      for tag2 in tag.children:
        if tag2.name == 'p':
          content.append(tag2.get_text(strip=True).replace('\n',' '))

  org = org.encode('utf-8')
  title = title.encode('utf-8')
  desc = desc.encode('utf-8')
  content = [c.encode('utf-8') for c in content]

  return (org, title, desc, content)

def get_ads(soup, campaign):
  """
  Get content of all ads for a specified campaign.
  @param soup Document tree to process.
  @param campaign Campaign string (see examples).
  @retval List of (url, title) pairs.
  """
  rex = re.compile('.*' + campaign + 'ad.{2,}\.html')
  tags = soup.find_all('a', href=rex)
  retval = [[t['href'], t.get_text().replace('\n',' ')] for t in tags]
  for v in retval:
    if not v[0].startswith('http'):
      v[0] = base_url + v[0]
  retval = [v for v in retval if len(v[1])>1]
  return retval

def strain_soup(soup):
  """
  Remove portions of the tree that will interfere with simple ad retrieval.
  @param soup Document tree to modify.
  @retval None.
  """
  sp_tag = soup.find(string='Super PACs and More').find_parent('div')
  for tag in sp_tag.next_siblings:
    tag.extract()
  sp_tag.extract()

def extract_ads(campaign, file_name=None, dump_output=True):
  """
  Extract all ads for a named campaign.
  @param campaign String campaign name.
  @param file_name File name to store result in.
  @param dump_output Boolean to dump output to terminal.
  
  """
  # Make soup.
  print 'Making soup...'
  f = urllib2.urlopen(main_url)
  soup = BeautifulSoup(f, 'html.parser')

  # Trim away everything after the campaign ads.
  print 'Stripping down the document tree...'
  strain_soup(soup)

  # Extract ads for campaigns.
  print 'Finding campaign ads...'
  urls = get_ads(soup, campaign) 
  print 'Found %i ads for %s campaign.' % (len(urls), args.campaign)

  # Open output file.
  if file_name:
    f = open(file_name,'w')

  # Scraping ads.
  print 'Scraping campaign ads...'
  for url in urls:

    # Scrape url.
    (org, title, desc, content) = scrape(url[0])

    # Concatenate all content into one string for file output.
    total_content = ''
    for c in content:
      total_content += c  + ' '

    # Write to output file.
    if file_name:
      f.write('%s\n%s\n%s\n%s\n' % (org, title, desc, total_content))
      f.write('='*40+'\n')

    # Write to terminal.
    if dump_output:
      print '='*40
      print 'processed url: %s' % url[0]
      print 'organization: %s' % org
      print 'title: %s' % title
      print 'desc: %s' % desc
      print '-'*40
      for c in content:
        print c  
        print '-'*40
      print '='*40
 


if __name__ == '__main__':

  # Parse command line arguments and provide help.
  desc_text = 'Scrape text from 2016 presidential campaign ads at %s.' % main_url
  parser = argparse.ArgumentParser(description=desc_text)
  parser.add_argument('campaign', help='Name of the presidential campaign to scrape.')
  parser.add_argument('-f', '--file', help='Filename to store result in.') 
  parser.add_argument('-o', '--output', help='Dump output to terminal.', action='store_true')
  args = parser.parse_args()

  try:
    extract_ads(args.campaign, args.file, args.output)
  except Exception as ex:
    print 'Error extracting ads: %s.' % ex
    print 'Exiting...'


     


