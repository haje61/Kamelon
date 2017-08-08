<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<link rel="stylesheet" href="defaultstyle.css" type="text/css">
<title>Testfile Template Toolkit</title>
</head>
<body>
[% FOREACH fold IN folds.keys.nsort %]<a href="#[% fold %]">[% node = folds.$fold %][% node.last %]</a></br>[% END %]
</br>
</br>
[% linenum = 0 %]
[% FOREACH line = content %][% linenum = linenum + 1 %][% IF folds.exists(linenum) %]<a name="[% linenum %]"></a>[% END%][% linenum  FILTER format('%03d') %]&nbsp;[% FOREACH snippet = line %]<font class="[% snippet.tag %]">[% FILTER replace('\040', '&nbsp;') %][% FILTER replace('\t', '&nbsp;&nbsp;&nbsp;') %][% FILTER html %][% snippet.text %][% END %][% END %][% END %]</font>[% END %]</br>
[% END %]</body>
</html>
