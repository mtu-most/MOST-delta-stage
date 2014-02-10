#Name: Welder
#Info: Mangle GCode to work on welder (2014-02-10)
#Depend: GCode
#Type: postprocess
#Param: speed(float:10) target extruder speed (mm/s)
#Param: mindist(float:1) minimum travel distance to switch off welder (mm)
#Param: ON1(str:G4 P0) Command to insert after travel (line 1)
#Param: ON2(str:M42 P2 Sinf) Command to insert after travel (line 2)
#Param: ON3(str:) Command to insert after travel (line 3)
#Param: ON4(str:) Command to insert after travel (line 4)
#Param: OFF1(str:G4 P0) Command to insert before travel (line 1)
#Param: OFF2(str:M42 P2 Snan) Command to insert before travel (line 2)
#Param: OFF3(str:) Command to insert before travel (line 3)
#Param: OFF4(str:) Command to insert before travel (line 4)

import sys

__author__ = 'Bas Wijnen <wijnen@debian.org>'
__date__ = '2014-02-10'
__license__ = 'GNU Affero General Public License http://www.gnu.org/licenses/agpl.html'

try:
	infilename = filename
	outfilename = filename
	ON = ''.join (['%s\n' % x for x in (ON1, ON2, ON3, ON4) if x])
	OFF = ''.join (['%s\n' % x for x in (OFF1, OFF2, OFF3, OFF4) if x])
except NameError:
	assert len (sys.argv) in (3, 5)
	infilename = sys.argv[1]
	outfilename = sys.argv[2]
	speed = float (sys.argv[3]) if len (sys.argv) > 3 else 40.
	mindist = float (sys.argv[4]) if len (sys.argv) > 4 else 1.
	ON = 'G4 P0\nM42 P2 Sinf\n'
	OFF = 'G4 P0\nM42 P2 Snan\n'
extruding = False
pos = [0., 0., 0., 0.]
erel = None
rel = False
edata = [0.,0.]

def parse (line):
	edata[0] = pos[3]
	global rel, erel, extruding
	if ';' in line:
		l = line[:line.find (';')]
	else:
		l = line
	components = l.split ()
	if len (components) == 0:
		return line
	if components[0] == 'G90':
		rel = False
	if components[0] == 'G91':
		rel = True
	if components[0] == 'M82':
		erel = False
	if components[0] == 'M83':
		erel = True
	if components[0] == 'G92':
		for w in components:
			if w[0] in 'XYZ':
				wh = ord (w[0]) - ord ('X')
				pos[wh] = float (w[1:])
			elif w[0] == 'E':
				pos[3] = float (w[1:])
	if components[0] not in ('G0', 'G1'):
		return line
	parts = {}
	for p in components[1:]:
		if p[0] in parts or p[0] not in 'XYZEF':
			print 'warning: %s' % line
			return line
		parts[p[0]] = float (p[1:])
	x = []
	for i, c in enumerate ('XYZE'):
		if c in parts:
			x.append (parts[c] if (rel if i < 3 or erel is None else erel) else parts[c] - pos[i])
			pos[i] += x[-1]
		else:
			x.append (0.)
	dist = sum ([t ** 2 for t in x[:3]]) ** .5
	if 'E' not in parts or x[3] <= 0:
		if extruding and dist > mindist:
			extruding = False
			return OFF + line
		return line
	del parts['E']
	t = x[3] / speed
	parts['F'] = dist / t * 60.
	ret = 'G1 ' + ' '.join (['%s%f' % (c, parts[c]) for c in parts])
	if not extruding:
		extruding = True
		return ON + ret
	edata[1] = pos[3]
	return ret


try:
	with open (infilename, "r") as f:
		lines = f.readlines ()

	with open (outfilename, "w") as f:
		for line in lines:
			f.write (parse (line.strip ()) + '\n')
except:
	print ('something was wrong:', sys.exc_value)
