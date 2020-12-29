from docutils import nodes


def setup(app):
	app.add_role('wlref', make_ref_link)
	return {
		'parallel_read_safe': True,
		'version': '0.1'
	}


def make_ref_link(name, rawtext, text, lineno, inliner, options={}, content=[]):
	url = 'https://reference.wolfram.com/language/ref/%s' % text
	node = nodes.reference(rawtext, text, refuri=url, **options)
	return [node], []
