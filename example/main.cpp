#include <wx/wx.h>

class App : public wxApp
{
public:
    bool OnInit() override;
};

wxIMPLEMENT_APP(App);

bool App::OnInit()
{
    wxFrame *frame = new wxFrame(nullptr, wxID_ANY, "Hello World");
    new wxStaticText(frame, wxID_ANY, "Hello World", wxDefaultPosition, wxDefaultSize, wxALIGN_CENTRE_HORIZONTAL);
    frame->Show();
    return true;
}
