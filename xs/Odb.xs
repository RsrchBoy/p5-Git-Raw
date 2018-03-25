MODULE = Git::Raw			PACKAGE = Git::Raw::Odb

Odb
new(class)
	SV *class

	PREINIT:
		int rc;
		Odb out;
		git_odb *odb;

	CODE:
		rc = git_odb_new(&odb);
		git_check_error(rc);

		Newxz(out, 1, git_raw_odb);
		out -> odb = odb;
		RETVAL = out;

	OUTPUT: RETVAL

Odb
open(class, directory)
	SV *class
	SV *directory

	PREINIT:
		int rc;
		Odb out;
		git_odb *odb;

	CODE:
		rc = git_odb_open(&odb,
			git_ensure_pv(directory, "directory")
		);
		git_check_error(rc);

		Newxz(out, 1, git_raw_odb);
		out -> odb = odb;
		RETVAL = out;

	OUTPUT: RETVAL

void
add_backend(self, backend, priority)
	Odb self
	SV *backend
	int priority

	PREINIT:
		int rc;

	CODE:
		rc = git_odb_add_backend(self -> odb,
			GIT_SV_TO_PTR(Odb::Backend, backend),
			priority
		);
		git_check_error(rc);

		if (!self -> backends)
			self -> backends = newAV();

		av_push(self -> backends, SvRV(backend));
		SvREFCNT_inc_NN(SvRV(backend));

void
add_alternate(self, backend, priority)
	Odb self
	SV *backend
	int priority

	PREINIT:
		int rc;

	CODE:
		rc = git_odb_add_alternate(self -> odb,
			GIT_SV_TO_PTR(Odb::Backend, backend),
			priority
		);
		git_check_error(rc);

		if (!self -> backends)
			self -> backends = newAV();

		av_push(self -> backends, SvRV(backend));
		SvREFCNT_inc_NN(SvRV(backend));

SV *
backend_count(self)
	Odb self

	CODE:
		RETVAL = newSVuv(git_odb_num_backends(self -> odb));

	OUTPUT: RETVAL

void
foreach(self, cb)
	Odb self
	SV *cb

	PREINIT:
		int rc;

	CODE:
		rc = git_odb_foreach(self -> odb,
			git_odb_foreach_cbb,
			git_ensure_cv(cb, "callback")
		);
		if (rc != GIT_EUSER)
			git_check_error(rc);

Odb_Object
read(self, id)
	Odb self
	SV *id

	PREINIT:
		int rc;

		git_oid oid;

		STRLEN len;
		const char *id_str;

		Odb_Object obj;

	INIT:
		id_str = git_ensure_pv_with_len(id, "id", &len);

	CODE:
		rc = git_oid_fromstrn(&oid, id_str, len);
		git_check_error(rc);

		rc = git_odb_read_prefix(&obj, self -> odb, &oid, len);
		if (rc == GIT_ENOTFOUND)
			XSRETURN_UNDEF;
		git_check_error(rc);

		RETVAL = obj;

	OUTPUT: RETVAL

SV *
write(self, data, type)
	Odb self
	SV *data
	SV *type

	PREINIT:
		int rc;
		git_oid id;

		STRLEN len;
		const char *d;

	CODE:
		d = git_ensure_pv_with_len(data, "data", &len);

		rc = git_odb_write(&id, self -> odb, d, len,
			git_ensure_iv(type, "type")
		);
		git_check_error(rc);

		RETVAL = git_oid_to_sv(&id);

	OUTPUT: RETVAL

void
refresh(self)
	Odb self

	CODE:
		git_odb_refresh(self -> odb);

SV *
hash (self, data, type)
	SV *self
	SV *data
	SV *type

	PREINIT:
		int rc;
		git_oid id;

		STRLEN len;
		const char *d;

	CODE:
		d = git_ensure_pv_with_len(data, "data", &len);

		rc = git_odb_hash(&id, d, len,
			git_ensure_iv(type, "type")
		);
		git_check_error(rc);

		RETVAL = git_oid_to_sv(&id);

	OUTPUT: RETVAL

void
DESTROY(self)
	SV* self

	PREINIT:
		Odb odb;

	CODE:
		odb = GIT_SV_TO_PTR(Odb, self);
		git_odb_free(odb -> odb);

		if (odb -> backends)
			av_undef(odb -> backends);

		Safefree(odb);
		SvREFCNT_dec(GIT_SV_TO_MAGIC(self));
