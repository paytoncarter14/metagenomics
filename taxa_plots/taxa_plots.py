import pandas as pd
import matplotlib.pyplot as plt

csvs = {}
csvs['body_site'] = pandas.read_csv('csv/body_site.csv', index_col='index').drop('body.site', axis=1)
csvs['water_type'] = pandas.read_csv('csv/water_type.csv', index_col='index').drop('water.type', axis=1)
csvs['suborder'] = pandas.read_csv('csv/suborder.csv', index_col='index').drop('suborder', axis=1)
csvs['sex'] = pandas.read_csv('csv/sex.csv', index_col='index').drop('sex', axis=1)
csvs['location'] = pandas.read_csv('csv/location.csv', index_col='index').drop('location', axis=1)

global_max = 0
for df in csvs.values():
    max = df.sum(axis=1).max()
    if max > global_max: global_max = max

relative = {}
for name, df in csvs.items():
    relative[name] = df.apply(lambda x: (x / x.sum()), axis=1)

combined = pd.concat(relative.values(), axis=0)

ax = combined.plot(kind='bar', stacked=True, figsize=(10,8), width=0.95)
ax.legend(loc='center left', bbox_to_anchor=(1.0, 0.5))
fig = ax.get_figure()
fig.savefig('taxa-bar-plot.png', bbox_inches='tight')